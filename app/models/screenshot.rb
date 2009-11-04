# -*- coding: iso-8859-1 -*-
  class Screenshot < ActiveRecord::Base
  has_one :photo, :as => :photoable  
  include Photoable
  
  serialize :keywords, Array
  serialize :knns, Array
  serialize :labels, Array  
  serialize :search_results
  
  
  def label_photos
    labels.map do |x|
      Photo.find x if Photo.exists? x
    end.compact
  end
  
  def knn_photos
    knns.map do |x|      
      Photo.find x if Photo.exists? x
    end.compact
  end  

  
  def labels
    if read_attribute(:labels).nil? 
      []
    else
      read_attribute(:labels)
    end
  end
  
  
  def knns
    if read_attribute(:knns).nil? 
      []
    else
      read_attribute(:knns)
    end
  end    
  
  # note that we add '0' to labels to mark selection
  def selected?
    labels.size > 0
  end
  
  
  def self.get_roc_data
    (1..10).each {|x| 
      puts Screenshot.compute_accuracy_rate(x).join(' ')
    }
  end
  
  def self.compute_accuracy_rate(r=10)
    
    query_count = 0 # total number of queries with at least one match
    match_count = 0 # total number of matches found for all queries
    n = 0 # total number of queries
    
    Screenshot.find(:all).each do |x|
                                       
      if x.labels.size > 0 
        
      knns = x.knns
            
#      as = knns[0..9] 
#      bs = knns[10..19]     
#      
#      if rand > 0.5
#        knns = bs.zip(as).flatten      
#      else
#        knns = as.zip(bs).flatten      
#      end
      
      
#      knns = as
#      knns = bs
      
      knns = knns[0..r-1]
               
        n = n + 1
        
        if knns.any? {|id| x.labels.include? id}

          query_count = query_count + 1          

          knns.each {|id| match_count = match_count + 1 if x.labels.include? id}
          
        end
        
      end      
    end
    
    [query_count, match_count, n]
  end
  
  def self.load_knns_with_scores
    input_file = 'xppdf_results1.txt'
    File.open(input_file).readlines.each do |line|
      query_photo_id, *matches = line.chomp.split
      
      screenshot = Photo.find(query_photo_id).photoable      
      knns = matches.map {|x| id,score = x.split(':'); id.to_i}
      screenshot.knns << knns[0..9]
      screenshot.save
    end
  end
  
  def self.load_knns(input_file)
    File.open(input_file).readlines.each do |line|
      #query_photo_id, *matches = line.chomp.split
      query_photo_id, *knns = line.chomp.split
      
      screenshot = Photo.find(query_photo_id).photoable      
      #knns = matches.map {|x| id,score = x.split(':'); id.to_i}
      screenshot.knns = knns[0..9].map {|x| x.to_i}
      screenshot.save
    end
  end

  
  def self.match_by_keywords_all!(options={})
    Screenshot.find(:all,options).each do |x|
      x.match_by_keywords!
    end
  end
  
  def match_by_keywords!
    search_phrase = keywords.join(' ')
    matched_pdf_pages = PdfPage.search_ferret(search_phrase, :limit => 20).map {|x| PdfPage.find(x)}
    matched_pdf_figures = matched_pdf_pages.map {|x| x.pdf_figures}.flatten.compact
    matched_photo_ids   = matched_pdf_figures.map {|y| y.photo.id}[0..9]
    write_attribute(:knns, matched_photo_ids)
    save
  end
  
  def self.match_by_ocr_all!
    Screenshot.find(:all).each do |x|
      knns,txt = x.match_by_ocr
      x.knns = knns[0..9]
      x.save
    end    
  end
  
  
  def self.output_knns(output_filename)    
    File.open(output_filename,'w') {|f| 
      Screenshot.find(:all).each {|x| 
          if x.labels.size>0            
            f.puts "#{x.photo.id} #{x.knns.join(' ')}"
          end
      }    
     }
  end
  
  
  def match_by_ocr
    require 'tempfile'  
    t = Tempfile.open('query')
    t.close
    tmp = t.path

    #temp_filename = '/tmp/3grams.bin'
   
    
    source_image = photo.local_path :original
    tmp_pgm    = "#{tmp}.pgm"
    tmp_tif    = "#{tmp}.tif"
    tmp_txt    = "#{tmp}.txt"
    tmp_3grams = "#{tmp}.bin"
    
    `convert #{source_image} #{tmp_pgm}`
    `convert -resize 200% #{tmp_pgm} #{tmp_tif}`
    puts "tesseract #{tmp_tif} #{tmp_txt}"
    `tesseract #{tmp_tif} #{tmp_txt.gsub('.txt','')}`
    ids = extract_3grams(tmp_txt, tmp_3grams)

    ocr_text = File.open(tmp_txt).readlines

    if ids.size > 0
    result_output = `ocr/imgdb-query.out ocr/workdir/ #{tmp_3grams}` 
    
   #puts result_output
        
    result_ids = result_output.split("\n").map do |x|
      x.chomp!
      id, path = x.split
      id.to_i
    end
    
    [result_ids, ocr_text]
   else
    
    [ [], ocr_text]
    end
  end
  
  def convert_to_code(ch)
    if ch == ?_
      code = 0
    elsif ch == ?*
      code = 1
    elsif ch >= ?0 and ch <= ?9
      code = ch - ?0 + 2
    elsif ch >= ?a
      code = ch - ?a + 12
    end
    code  
  end
  
  def extract_3grams(input_file, output_file)
    ids = []
    lines = File.open(input_file).readlines
    lines.each do |line|
      
      #cra => cra
      #ray => ray
      #ay  => ay_
      #y   => y__
      #  � => __*
      #_î => *__
      #îi => **_
      
      line.chomp!
      line.downcase!
      line = line.gsub(/[ ]/,'*')
      line = line.gsub(/[^0-9a-zA-Z*]/,'_')   
      
      for i in (0 .. line.size-3)     
        
        token = line[i..i+2]
        
        if not /[\_\*]{3,3}/.match(token)
          codes = token.split('').map{|x| convert_to_code(x[0])}
          id    = codes[0]*38*38 + codes[1]*38 + codes[2]
          
          ids << id       
          #puts "#{token} -> #{codes.join(' ')} -> #{id}"     
        end
        
      end
    end
    
    
    puts "writing #{'%4d' % ids.size} 3grams to #{output_file}"
    
    f = File.new(output_file,  "wb")
    f.write([ids.size].pack('i1'))
    f.write(ids.pack('i*'))
    f.close
  
    
    #f = File.new(output_file,  "rb")
    #data = f.read
    #puts data.unpack('i*')
    #f.close
    
    ids
    
  end
  
  
  def self.expand_keyword_shorthands_for_all
    
    Screenshot.find(:all).each do |x|      
      x.keywords = expand_shorthands(x.keywords)
      x.save
    end
    
  end
  
  
  def self.batch_import_from_directory(directory)
    Dir.glob("#{directory}/*.gif").each_with_index do |x,i|
      
      #if i >= 720 #and i < 70
        keywords = File.basename(x,'.gif').underscore.split('_')
        keywords.uniq!
        puts "#{i} importing #{x} [exist? #{File.exists?(x) ? "yes" : "no"}] [#{keywords.join(',')}]"          
        begin
          Screenshot.create :keywords => keywords, :photo_file => x
        rescue          
          puts "#{x} failed because #{$!}"
        end
      #end
    end
    true
  end
  
  
  
  
  
#  require 'rubygems'
#  require 'bossman'
#  include BOSSMan
  
  
  
  def self.expand_shorthands(words)
     # shorthands
    shorthands = {
    'opts' => 'options',
    'scr' => 'screen',
    'accs' => 'accessibility',
    'utils' => 'utilities',
    'wiz' => 'wizard',
    'fltr' => 'filter',
    'progs' => 'programs',
    'srvcs' => 'services',
    'mgnt' => 'management',
    'svcs' => 'services',    
    'props' => 'properties',
    'hw' => 'hardware',
    'dtop' => 'desktop',
    'conn' => 'connection',
    'maint' => 'maintenance',
    'fav' => 'favorite',
    'adv' => 'advanced',
    'btn' => 'button',
    'acct' => 'account',
    'kbrd' => 'keyboard'}
    words.map do |x|
      if shorthands[x]
        shorthands[x]
      else
        x
      end
    end    
  end
  
  
  def search!
    
    BOSSMan.application_id = "mpTwLWbV34HU4yCQWbamzdaMAB.pfOLjc1XLS2DCYPrhqtgfaBK2GYawdC61r3vb1Q"    
    
    # shorthands
    shorthands = {
    'opts' => 'options',
    'scr' => 'screen',
    'accs' => 'accessibility',
    'utils' => 'utilities',
    'wiz' => 'wizard',
    'fltr' => 'filter',
    'progs' => 'programs',
    'srvcs' => 'services',
    'mgnt' => 'management',
    'svcs' => 'services',    
    'props' => 'properties',
    'hw' => 'hardware',
    'dtop' => 'desktop',
    'conn' => 'connection',
    'maint' => 'maintenance',
    'fav' => 'favorite',
    'adv' => 'advanced',
    'btn' => 'button',
    'acct' => 'account',
    'kbrd' => 'keyboard'}
    
    
    
    ws = self.keywords
    ws = ws.map do |x|
      if shorthands[x]
        shorthands[x]
      else
        x
      end
    end
    
    ws << 'xp'
    
    keywords_string = ws.join(' ')      
    #puts keywords_string
    
    #return
    
    boss = BOSSMan::Search.web(keywords_string, { :count => 3, :filter => "-hate" })
    
    #puts "keywords: #{keywords_string} \t has no result: #{boss.totalhits}"
    print " #{self.id} "
    if self.id % 25 == 0
      print "\n"
    end
    
    if boss.totalhits.to_i > 0
      
      text = ''
      boss.results.each do |result|
        text = text + "<a href=#{result.url} class='title'>" + result.title + "</a>" + "<div class=abstract>" + result.abstract + "</div>" +
          "<div class=url>" + result.url + "</div><br>"       
     end
   
    self.update_attributes :search_result => text        
        
    else
      puts "keywords: #{keywords_string} \t generates no result!"
    end    
    

    
  end
  
  def match(dataset)
    require 'tempfile'  
    t = Tempfile.open('query')
    t.close
    temp_filename = t.path + '.pgm'
   
    #logger.info "matching #{photo.local_path} agasint #{dataset}"
    puts "matching #{photo.local_path} against #{dataset}"
    
    `convert #{photo.local_path} #{temp_filename}`

    # issue the imgdb-query command to obtain a list of ids of the matched photos    
    
    #result_output = `imgdb/imgdb-query.out imgdb/workdir/#{dataset} #{temp_filename}` 
    exe = "/csail/vision-trevor7/tomyeh/engine/bin/imgdb-query.out"
    workdir = "/csail/vision-trevor7/tomyeh/pdfs/v2"
    result_output = `#{exe} #{workdir} query_pgm #{temp_filename}` 
    
    puts result_output
        
#    self.result_ids = result_output.split("\n").map do |x|
#      x.chomp!
#      id, path = x.split
#      id.to_i
#    end
#    
#    self.result_ids
  end  
  
    
end
