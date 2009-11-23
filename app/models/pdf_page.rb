class PdfPage < ActiveRecord::Base
  belongs_to :pdf_book
  has_many :pdf_figures

  def extract_labels_and_refs

    s = StringScanner.new(text)

    labels = {}
    refs = {}
    
    pattern = /([ \n]*)(Figure \d+[-\.]?\d*)/i
    while s.scan_until(pattern)
      
      pre_whitespaces = s[1]
      figure_name = s[2]
      #p pre_whitespaces

      is_label = pre_whitespaces.size >= 4
     
      figure_name.downcase!

      # number of words
      n = 10      

         
      pre_match = (s.pre_match || '')
      post_match = (s.post_match || '')

     [pre_match, post_match].each {|str|

        # removing starting commas, periods, and colons
        str.gsub!(/^[\.:]/,'')

        # re-connect dash separated words
        str.gsub!(/-\n\s+/,'')
      }

      next_words = post_match.split
      next_words = next_words.slice(0,n)
      next_string = next_words.join(' ')
 
      
      prev_words = pre_match.split
#      if s.pre_match.match(/\. (.*?)$/m)
 #         prev_words = $1.split
  #    else
#        prev_words = (s.pre_match || '').split
        #prev_words = ["size:#{prev_words.size}"]
   #   end     

      # pick no more than N words
      prev_words = prev_words.reverse.slice(0,10).reverse# if prev_words.size > n
      prev_string = prev_words.join(' ')

 
      # removing starting page numbers
      prev_string.gsub!(/^\d*/,'')

      figure_hash = {:name => figure_name, :page => number}

      if is_label 
        figure_hash[:text] = next_string
        labels[figure_name] = figure_hash
      else
        figure_hash[:text] = prev_string + " " + figure_name + " " + next_string
        refs[figure_name] = figure_hash
      end

    end

    [labels, refs]
  end


  def next
    PdfPage.find_by_pdf_book_id_and_number(pdf_book.id,number+1)
  end

  def prev
    PdfPage.find_by_pdf_book_id_and_number(pdf_book.id,number-1)
  end

  
  def extract_text
    
    puts "#{self.id}: extracting text from book [#{pdf_book.id}: #{pdf_book.title}], page [#{number}]"
    
    tmpfile = 'tmpimport.txt'
    cmd = "pdftotext -f #{self.number} -l #{self.number} -layout #{pdf_book.pdf_localpath} #{tmpfile}"
    system cmd
    
    txt = File.open(tmpfile).read
    #puts txt
    
    self.text = txt
    self.save
    
  end
  
  def image_url
    pdf_book_id = self.pdf_book.id
    '/pdf_images/%d/%d-%0.6d.jpg' % [pdf_book_id, pdf_book_id, self.number]    
  end
  
  
  require 'ferret'
  require 'fileutils'
  include Ferret
  include Ferret::Index
  def self.path_to_index
    'db/ferret'
  end
  
  def self.index_ferret

    field_infos = FieldInfos.new(:store => :yes,
                                 :index => :yes,
                                 :term_vector => :no)

    
    field_infos << FieldInfo.new(:content, :store => :no)
    
    Ferret::Index::Index.new(:path => path_to_index,
                             :field_infos => field_infos, :create => true) do |index|
      
      n = self.count
      self.find(:all).each_with_index do |page,i|
        puts "indexing #{i+1} of #{n} documents"        
        
        document = {:id => page.id, :content => page.text}
        index << document
        #index.search_each(query) {|id, score| puts "#{score} #{index[id].load}"}
      end
      
    end
  end

  def self.search_ferret(search_phrase, options = {})
    index = Index.new(:path => path_to_index) 
    
    results = []
    total_hits = index.search_each(search_phrase, options) do |doc_id, score| 
      #results << "  #{score} - #{index[doc_id][:id]}" 
      results << index[doc_id][:id]
    end
    
    puts "#{total_hits} matched your query:\n" + results.join("\n")
    
    index.close()   
    
    results    
  end

  def first_words(n=20)
    text.split.slice(0,n).join(' ').gsub(/^\d*/,'')
  end

  def image_url    
    '/pdf_images/%d/%d-%0.6d.jpg' % [pdf_book.id, pdf_book.id, number]
  end

  def heading

    lines = open("public/data/bookmarks/#{pdf_book.title.gsub(' ','-')}.csv").readlines


    previous_heading = nil
    top_level_heading = nil
    lines.each do |x|
      
      
      level,n,text,page = x.scan(/".*",(\d*),(\d*),"(.*)",".*",(\d*)/)[0]
      level = level.to_i

      if level == 1
        top_level_heading = text
      end

      
      if page.to_i > number
        break
      end

      previous_heading = text
     
    end

    [top_level_heading, previous_heading].compact
 end

end
