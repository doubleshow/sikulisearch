# -*- coding: iso-8859-1 -*-
class Query < ActiveRecord::Base

  has_one :photo, :as => :photoable  

  include Photoable
  
  serialize :target_ids, Array
  serialize :result_ids, Array  
  
  def results
    if not result_ids.nil? 
      result_ids.slice(0,10).map {|x| Photo.find(x) if Photo.exists?(x)}.compact
    else
      []
    end
  end
  
  def self.import_and_match
    Dir.glob('query_import/mac/korean/*.png').each do |x|
      @query = Query.create :photo_file => x, :source=>'mac/spanish'
      @query.match!
    end

  end

  def self.import
    Dir.glob('query_import/app/*.png').each_with_index do |x,i|
      puts i
      @query = Query.create :photo_file => x, :source=>'test/app'
    end
  end

  def self.import_from_screenshots
    Screenshot.find(:all).shuffle.slice(0,150).each_with_index do |x,i|
      puts i
      f = x.photo.local_path
      puts f
      @query = Query.create :photo_file => f, :source=>'test/xp'
    end
    true
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
        
    self.result_ids = result_output.split("\n").map do |x|
      x.chomp!
      id, path = x.split
      id.to_i
    end
    
    [self.result_ids, ocr_text]
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
  

  def match!
    photo_ids = match
    update_attribute(:result_ids, photo_ids)
  end  

  def cached_results_path
    "cache/#{id}.yaml"
  end

  def clear_cached_results
    `rm #{cached_results_path}`
  end

  def cached_results
    if not File.exists?(cached_results_path)          
      photo_ids = match_brandyn
      File.open(cached_results_path,'w') do |f|
        YAML.dump(photo_ids,f)
      end
    end

    YAML.load_file(cached_results_path)
  end
  

  def match(rerun = false)
    if rerun
      clear_cached_results
    end
    ids   = cached_results.map{|x| x["pcdoc_id"]}
    votes = cached_results.map{|x| x["votes"]}
    #match_brandyn
    #[22860,44263,17216,17314,65686,39150,44264,35545,33631,33582]
    [ids,votes]
  end

  def match_brandyn
    
    def urlsafe_encode64(bin)
      [bin].pack("m0").tr("+/", "-_")
    end

    def do_match(port)
    
      require 'base64'
      host = "http://ln.dappervision.com:#{port}/"
      base = "http://poq.csail.mit.edu:3100"
      url64 = urlsafe_encode64(base + photo.url).split.join.gsub('=','')
      puts base + photo.url
      cmd = "curl -s '#{host}?method=1&output_format=json&version=0&query_path=#{url64}&query_path_pad=2'"
      puts cmd
      json = `#{cmd}`
      
      require 'json'
      results = JSON.parse(json)["results"]
      #ids = results.map {|x| x["pcdoc_id"]}
      #votes = results.map {|x| x["votes"]}
      #ids
      results
    end

    combined_results = []
    [9080,9089].map do |x|
      combined_results += do_match(x)
    end

    combined_results.sort! do |a,b|
      b["votes"] <=> a["votes"]
    end

    #ids = combined_results.map {|x| x["pcdoc_id"]}
    #ids.select {|x| x != -1}.uniq
    combined_results.select{|x| x["pcdoc_id"] != -1}

  end


end
