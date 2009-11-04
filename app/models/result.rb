class Result

    attr_accessor :pages,:all_tags
    def initialize
      @pages = []
      @amt_tags = []
      @all_tags = {}
    end



  class Page
    attr_accessor :title, :description, :thumb, :action_link, :id,
    :num_images, :num_words, :num_unique_images, :score, :tags, :photo_id

    def count_keywords(keywords,text)   
      counts = []    
      keywords.each do |keyword|        
        counts << text.scan(/#{keyword}/mi).size
      end    
      counts
    end

    def compute_score(search_terms)
      if @score.nil?
        fc  = FeatureComputer.new(self)
        @score = fc.score(search_terms)
      end
      @score
    end        

    def extract_tags(fields)
      stopwords = {}
      ['but','are','its','just','or','each','chapter','was','than','them','withint','their','figure','an','any','by','be','on','here','only','this','we','will','with','have','of','a','as','at','is','it','if','and','to','the','for','in','can','you','your','that','these'].each       {|x| stopwords[x]=1}
      

      @tags = []
      fields.each {|f|
        # at least two letters
        @tags += f.scan(/[a-zA-Z][a-zA-Z]+/).flatten
      }
      @tags.each {|x| x.downcase!}
      @tags.uniq!
      @tags.delete_if {|x| stopwords.has_key? x}      
    end

  end

  # class PdfPage < PdfPage

  #   def initialize(photo, pdf_figure)
  #     super(pdf_figure)
  #     @thumb = photo.url
  #   end    

  # end

  class PdfPage < Page
    attr_accessor :bookmark, :amazon, :label, :ref


    def initialize(pdf_figure)
      pdf_page = pdf_figure.pdf_page

      @photo_id = pdf_figure.photo.id
      @thumb = pdf_figure.photo.url
      @title = pdf_page.pdf_book.title
      @num_images = pdf_page.pdf_figures.size
      @num_unique_images = @num_images # typicall no dupliacte on a single pdf page
      @num_words = pdf_page.text.split.size

      h = pdf_page.heading
      @bookmark = h.join(' > ') unless h.empty?
      @amazon = "http://www.amazon.com/s/ref=nb_ss?url=search-alias%3Daps&field-keywords=#{title.gsub(' ','+')}"

      @label = pdf_figure.label      
      @ref   = pdf_figure.ref
      image_html = "<img src='#{pdf_figure.photo.url(:thumb)}' height=15 class='thumb'/>"

      tag_strings = []

      @description = ''
      if label
        #img_text = label[:text].sub(/#{label[:name]}/i,image_html)
        tag_strings << label[:text]

        @description += "<span class='pageno' style='float:left'>(p.#{label[:page]})</span>"
        @description += " <table><tr><td align='center'>#{image_html}</td><tr>"
        @description += " <td align='center'>#{label[:text]} ... </td></tr></table>"
        #@description +=  "#{label[:text]}"
      end
      if ref
        tag_strings << ref[:text]

        ref_img_text = ref[:text].sub(/#{ref[:name]}/i,image_html)

        @description += "<br>" if label
        @description += "<span class='pageno'>(p.#{ref[:page]})</span>"
        #@description += " <b>Text:</b> "
        @description += " ... #{ref_img_text}"
      end
      if label.nil? and ref.nil?
        first_words = pdf_figure.pdf_page.first_words
        tag_strings << first_words

        @description += "<span class='pageno'>(p. #{pdf_figure.pdf_page.number})</span> ... "
        @description += first_words
      end

      @action_link = "<a href='#{pdf_figure.pdf_page.image_url}'>Preview</a>"

      @id = "#{pdf_figure.class}:#{pdf_figure.id}"

      
      extract_tags(tag_strings)

    end


    def to_s
      ["title: #{title}","amazon: #{amazon}","bookmark: #{bookmark}",
       "desc.: #{description}"
      ].join("\n")
    end

  end

  class WebPage < Page
    attr_accessor :html, :text, :above, :below, :imageurl, :url, :domain

    def initialize(web_figure)
      @id = "#{web_figure.class}:#{web_figure.id}"
      @photo_id = web_figure.photo.id
      @thumb = web_figure.photo.url      

      if File.exists?(web_figure.webpage_localpath)
        @html = File.open(web_figure.webpage_localpath).read 

        text_file = web_figure.webpage_text_localpath
        if not File.exists?(text_file)
          File.open(text_file,"w") {|f| 
            f.print @html.gsub(/(alt=['"]?(\w* ?)+['"]?)/im,'')}
          `lynx -dump #{text_file} > #{text_file}`
        end
        @text = File.open(text_file).read 

      else
        @html = ''
        @text = ''
      end


      if @html.match(/<title>(.*?)<\/title>/mi)
        @title = $1.strip
        @title = nil if @title.size > 200
      end 

      @url  = web_figure.pageurl
      @imageurl = web_figure.imageurl

      @url.match(/http:\/\/(.*?)[\/$]/)
      @domain = ($1 || '').strip

      x = File.basename(web_figure.imageurl)
      s = StringScanner.new(@text)
      s.scan_until(/\[#{x}\]/)        
      
      @above = nil
      @below = nil

      def cleanup(str)
        # remove horizontal line
        str.gsub!(/_____*/,'')  
        # remove bracketed image link
        str.gsub!(/\[.*\]/,'')
        str
      end

      if s.pre_match    
        @above = cleanup s.pre_match.split.reverse.slice(0,15).reverse.join(' ')
      end
      if s.post_match
        @below = cleanup s.post_match.split.slice(0,15).join(' ')
      end

      if @above and @below

      @description = (@above||'') + "<br>" + 
        "<img src='#{web_figure.photo.url(:thumb)}' height='20' class='thumb'/><br>" +
        (@below||'')
      else
        @description = text.gsub(/\[.*?\]/m,'').split.slice(0,15).join(' ')
      end

      @action_link = "<a href=/webpages/'#{web_figure.webpage_url}'>Cached</a>"

  

      imgsrcs = html.scan(/<\s*img.*?src\s*=(.+?)\s/mi).flatten      
      @num_unique_images = imgsrcs.uniq.size
 
#      imgsrcs1 = text.scan(/\[.*?\.[a-zA-Z]{3,4}\]/).flatten
#      p imgsrcs1.size

      @num_images = imgsrcs.size#html.scan(/<\s*?img/i).size
      @num_words = text.scan(/\w+/).size
#      puts "#{@num_images}= #{imgsrcs.size}"

      extract_tags([@above,@below].compact)
  end


    def is_gallery?
      [num_words,num_images]
    end
    
    def is_walkthrough?
      if @walkthrough.nil?
        f1,f2,f3,f4 = walkthrough_features
        @walkthrough = f1>=3 or f2>=3 or f3>=3 or f4>=6
      end
      @walkthrough
    end

    def walkthrough_features

      def debug(x)
        nil#puts x
      end

      if @text.match(/^References/) and  @text.match(/(.*)^References/m)
        str = $1
      else
        str = @text
      end

      debug @url
           
      # remove all links
      str.gsub!(/\[\d*?\]/,'')     

      num_step_words =  str.scan(/step *\d+/mi).size 
      debug num_step_words

      num_ul_images = str.scan(/^\s*\*[^\*]*?\[.*?\].*?^\s*\*/m).size
      debug num_ul_images      

      num_ol_items = str.scan(/^\s*\d+\D/).size
      debug num_ol_items    
            
      num_ol_images = 0
      s = StringScanner.new(str)
      while num_ol_items > 1 and s.scan_until(/^\s*(\d+)\D.*?\[.*?\].*?^\s*(\d+)\D/m)
        
        debug s.matched
        debug "#{s[1].to_i} #{s[2].to_i}"

        num_ol_images += 1 if s[1].to_i + 1 ==  s[2].to_i

        s.pos = s.pos - s[2].size - 1
      end
      debug num_ol_images
      
      
      first_words = @text.scan(/^\s*(\d*|\*)\.?\s*([A-Z][a-z]+)/).map{|x|x[1]}.flatten      
           
      h = {}
      first_words.each {|x| h[x] = 1}
      
      str = first_words.join(' ')
      action_words = ['next','click','right-click','drag','open','close','scroll','enter']

      num_action_first_words = action_words.map {|x|
        str.scan(/#{x}/i).size        
                
      }.sum

      [num_step_words, num_ol_images, num_ul_images, num_action_first_words]
                 
    end


    def to_s      
      "title: #{title}\n" +
        "url  : #{url}\n" +
        "image: #{imageurl}\n" +
        "above: #{above}\n" +
        "below: #{below}\n" +
        "desc.: #{description}\n"
      #puts "
    end    

  end

  class BingWebPage < Page

    attr_accessor :url
    def initialize(r)
      @url = r["Url"]
      @title = r["Title"]        
      @description = r["Description"]
    end

    def compute_score(keywords)
      100
    end

  end

  class BingImagePage < Page

    attr_accessor :url

    def initialize(r)
      @thumb = r["Thumbnail"]["Url"]
      @url = r["Url"]
      @title = r["Title"]        
      @description = r["Summary"]
    end


    def compute_score(keywords)
      100
    end

  end


  class GarbagePage < BingWebPage
  end


  class FeatureComputer
    def initialize(page)
      @page = page
    end

    def is_walkthrough?
      is_web_page? and @page.is_walkthrough?
    end

    def has_text_above?
      is_web_page? and not @page.above.nil? and not @page.above.strip.empty?
    end

    def has_text_below?
      is_web_page? and not @page.below.nil? and not @page.below.strip.empty?
    end

    def has_title?
      not @page.title.nil? and not @page.title.empty?
    end

    def has_bookmark?
      is_pdf_page? and not @page.bookmark.nil?
    end

    def has_label?
      is_pdf_page? and not @page.label.nil?
    end

    def has_ref?
      is_pdf_page? and not @page.ref.nil?
    end

    def is_host?(hostname)
      is_web_page? and not @page.url.match(/#{hostname}/i).nil?
    end

    def num_images
      @page.num_images
    end

    def num_unique_images
      @page.num_unique_images
    end

    def num_words
      @page.num_words
    end

    def is_pdf_page?
      @page.class == PdfPage
    end

    def is_web_page?
      @page.class == WebPage
    end

    def title_has_search_terms?(search_terms)
      has_title? and  search_terms.any? {|x|  @page.title.match(/#{x}/i)}
    end

    def text_above_has_search_terms?(search_terms)
      has_text_above? and search_terms.any? {|x| @page.above.match(/#{x}/i)}
    end

    def text_below_has_search_terms?(search_terms)
      has_text_below? and search_terms.any? {|x| @page.below.match(/#{x}/i)}
    end
    
    def has_few_unique_images?
      @page.num_unique_images <= 3
    end

    def has_only_one_image?
      @page.num_unique_images == 1
    end

    def has_many_unique_images?
      @page.num_unique_images >= 30
    end

    def top_100_most_image_domain?      
      if is_web_page?
        top_urls = {}
        File.open('top_100_urls.lst').each_line {|x| 
          domain,count = x.split          
          if @page.domain == domain
            return true
          end
        }          
      end
      false
    end

    def has_text_around
      [has_text_above?,has_text_below?,has_label?,has_ref?].select{|x|x}.size.to_f/2
    end

    def title_not_too_short
      num_title_words = (@page.title || '').split.size
      [num_title_words.to_f/20,1].min
    end

    def features(search_terms = [])
      
      binary_feature_def = 
        {:is_pdf_page? => 1,
        :is_web_page? => 1,
        :is_walkthrough? => 2,
        :has_text_above? => 3, 
        :has_text_below? => 3, 
        :has_title? => 5, 
        :has_label? => 3,
        :has_ref? => 3,
#       :is_host?('microsoft'),
       :has_bookmark? => 3,
       :top_100_most_image_domain? => 4,
       :has_only_one_image? => 3,
       :has_few_unique_images? => 3,
       :has_many_unique_images? => 1
     }


# has_many_unique_images?
# has_title?
# top_100_most_image_domain?
# has_bookmark?
# is_pdf_page?
# is_web_page?
# has_label?
# has_few_unique_images?
# has_text_above?
# has_ref?
# is_walkthrough?
# has_only_one_image?
# has_text_below?
      numerical_feature_def = {
        :title_not_too_short => 4,
        :has_text_around => 4
      }


      query_dependent_feature_def =
        {
        :title_has_search_terms? => 5,
        :text_above_has_search_terms? => 4,
        :text_below_has_search_terms? => 4
      }

      binary_feature_values = binary_feature_def.entries.map { |x,w| 
#        puts x
        [send(x) ? 1 : 0, w]
      }

      numerical_feature_values = numerical_feature_def.entries.map { |x,w| [send(x),w]}

      query_dependent_feature_values = query_dependent_feature_def.entries.map { |x,w| 
        [send(x,search_terms) ? 1 : 0, w] }

      binary_feature_values + numerical_feature_values + query_dependent_feature_values
    end

    def score(search_terms = [])     

      weighted_sum = lambda {|x| x.map {|v,w| v*w}.sum}

      all_features = features

      # numerical_features = 
      #   [
      #    num_images, num_unique_images, num_words
      #   ]

      # query_dependent_features = 
      #   [
      #  title_has_search_terms?(search_terms),
      #  text_above_has_search_terms?(search_terms),
      #  text_below_has_search_terms?(search_terms)
      #   ].map{|x| x ? 1 : 0 }




      #binary_features + numerical_features + query_dependent_features    
      
      score = weighted_sum.call(features)
      score
    end

  end


  def compute_features

    @pages.each {|p|
      fc = FeatureComputer.new(p)
      p fc.compute(['system','preferences'])
    }
    
  end


  def compute_score!
    @score = @page.compute_score('system preferences')
  end


  require 'json'

  def bing(keywords,source)

    count = 10
    query_string = keywords.join('+')

    appid = 'B1E908A93EB15554C779BFDCCF46F55BBF04A4ED'

    if source == :image
      url = "http://api.search.live.net/json.aspx?Appid=#{appid}&query=#{query_string}&sources=image&image.count=#{count}&image.filters=Style:Graphics"
    elsif source == :web
      url = "http://api.search.live.net/json.aspx?Appid=#{appid}&query=#{query_string}&sources=web"
    else
      return nil
    end

    
    res = `curl -s "#{url}"`
    res = JSON.parse(res)

    if source == :image
      results = res["SearchResponse"]["Image"]["Results"]    
    else
      results = res["SearchResponse"]["Web"]["Results"]    
    end

    results

  end

  def add_by_photo_ids(photo_ids, amt_tag = :normal)
    figures = photo_ids.map {|x| Photo.find(x).photoable if Photo.exists?(x)}.compact   
    
    figures.each_with_index do |f,i|
      puts "adding result #{i+1} of #{figures.size}"

      if f.class == WebFigure
        page = WebPage.new(f)
#        @amt_tags << amt_tag
      elsif f.class == PdfFigure
        page =  PdfPage.new(f)
#        @amt_tags << amt_tag
      end

      @pages << page

    end
  end

  def add_fake_pdf_page(photo,fake_pdf_figure)
    fake_pdf_page =  PdfPage.new(fake_pdf_figure)
    fake_pdf_page.thumb = photo.url
    @pages << fake_pdf_page
    @amt_tags << :fake
  end

  def add_by_bing_image(keywords,n)
    xs = bing(keywords,:image)
    @pages += xs.slice(0,n).map{|x| BingImagePage.new(x)}
  end
  
  def add_by_bing_web(keywords,n)
    xs = bing(keywords,:web)
    @pages += xs.slice(0,n).map{|x| BingWebPage.new(x)}
  end

  def add_by_bing_garbage(keywords,n)
    xs = bing(keywords,:web)
    @pages += xs.slice(0,n).map{|x| GarbagePage.new(x)}
  end

  def to_exhibit
    exhibit = Exhibit.new(self)
    @pages.each_with_index {|x,i| 
      puts "\n===[#{i+1}]====================================================================="
      print x.to_s
      exhibit.add(x)
    }
    exhibit
  end

  def save_exhibit(dest=nil)
    to_exhibit.save(dest)
  end

  def score_pages
    @pages.each {|p|
      fc = FeatureComputer.new(p)
      fc.compute(['system','preferences'])
    }
  end

  def sort(search_terms)
    @pages.each {|p| 
      p.compute_score(search_terms)}
    @pages.sort! {|a,b| b.score <=> a.score}    
  end

  def self.test
    #    ids += [28443, 49846, 41128, 22799, 22897, 71269, 44733, 49847, 39214, 39165]
    #ids = [40836, 40785, 40838, 59962, 36560, 59961, 36562, 36561, 72213, 85046, 60633]
    #ids = [83790, 84503, 83662, 83666, 84673, 50540, 83854, 84113, 83382, 83508]

    ids = Query.find(1197).result_ids

    result = Result.new
    result.add_by_photo_ids(ids[0..9])
    #result.add_by_bing_web("display properties".split)
    #result.pages.shuffle!
    result.sort('system preferenes')
    result.save_exhibit('tmp.json')

    
    #result.compute_features
    true

  end


  class Exhibit

    def initialize(result)
      @items = []      

      @all_tags = {}

      pages_with_tags = result.pages.select do |page|

        page.class == PdfPage || page.class == WebPage

      end

      pages_with_tags.each do |page|
        page.tags.each do |tag|
          @all_tags[tag] = (@all_tags[tag]||0) + 1
          end
      end      
    end

    def add(page)

      item = {}
      rank = @items.size+1

      item["label"] = '%2.0d' % rank

      item["title"] = page.title || 'Untitled'
      item["radio"] = "#{rank}:#{page.class.to_s.split('::')[-1]}:#{page.photo_id}"
      item["score"] = page.score.to_s
      


      if page.thumb
        item["thumb"] =  page.thumb
      end

      if page.class == WebPage

        #item["tag"] = "web"
        
        item["titleurl"] = page.url
        if page.is_walkthrough?
          item["resourceType"] = "walkthrough"
          item["tag"] = "walkthrough"
        else
          item["resourceType"] = "general"
        end

        item["description"] = page.description
        item["source"]  = page.url.sub('http://','')
        item["actionLink"] = page.action_link
#        item["tags"] = page.tags
        item["sites"] = page.domain
      item["tags"] = page.tags.select {|t| @all_tags[t] > 1}


      elsif page.class == PdfPage

        item["tag"] = "book"
        item["resourceType"] = "Book"
        item["titleurl"] = page.amazon
        item["description"] = page.description
        item["source"] = page.bookmark || page.title
        item["actionLink"] = page.action_link
 #       item["tags"] = page.tags

      item["tags"] = page.tags.select {|t| @all_tags[t] > 1}

      else

        item["titleurl"] = page.url 
        item["description"] = page.description || ''
        item["source"] = page.url.sub('http://','')


      end

      # convert all chracters to utf8 to prevent to_json from
      # blowing up
      # citem = {}
      # item.each {|k,v|         
      #   if v.class == String
      #     citem[k] = v.toutf8 
      #   elsif v.class == Array
      #     citem[k] = v.map{|y| y.toutf8}
      #   end
      #   }
      #    item = citem


      # print the exhibit item
      puts "\n\n"
      puts "EXHIBIT:"
      if item
        item.each {|x,y|
          puts "[#{x}] #{y}"
        }
      end

      begin
        item.to_json # make sure it can be turned into json
        @items << item    
      rescue
      end

    end

    def save(dest)

      exhibit = {}      
      exhibit[:types] = {"Result" => {"pluralLabel" => "Results"}}
      exhibit[:items] = @items

      open(dest,'w') {|f| f.puts exhibit.to_json }

    end

  end

  def self.create_map
    f = File.open('orders.yaml')
    orders = YAML.load(f.read)
    f.close

 
    photo_ids = orders.flatten.uniq


    
    id  = 1
    ids = {}
    photo_ids.each {|x|
      ids[x] = id
      id += 1
    }

    f = File.open('ranksvm.orders','w') {|f|
    orders.each do |x|
      f.puts x.map{ |y| ids[y] }.join(' ')          
    end
    }

    File.open('ranksvm.features','w') {|f|
    File.open('ranksvm.fs').readlines.each {|x|
      id,*rest = x.split
#      puts id
      f.puts(([ids[id]]+rest).join(' '))
    }
    }
      

  end


  def self.compute_features_for_ranksvm

    f = File.open('orders.yaml')
    orders = YAML.load(f.read)
    f.close

    File.open('ranksvm.fs','w') do |out|   

      photo_ids = orders.flatten.uniq

      photo_ids.each do |photo_id|
        photo = Photo.find(photo_id)

        figure = photo.photoable
        if figure.class == WebFigure
          w = WebPage.new(figure)
        elsif figure.class == PdfFigure
          w = PdfPage.new(figure)
        end

        fc = FeatureComputer.new(w)
        fs = fc.features.map{|v,w|v}

        out.puts(([photo_id]+fs).join(' '))
        puts ([photo_id]+fs).join(' ')
      end

    end
  end
  
  def self.find_features
    cnt = 0
    f = open('all_features.lst','w')
    WebFigure.find(:all,:offset=>5000, :limit=>1000).each do |x|

      begin      
        w = WebPage.new(x)
        fc = FeatureComputer.new(w)


        fs = fc.compute

        if fs[12] > 50
          puts fs[12]
          cnt = cnt + 1
          puts cnt
        end


        puts "#{x.id} #{fs.join(' ')} #{w.url}"
        f.puts "#{x.id} #{fs.join(' ')} #{w.url}"
        
      rescue
        puts "something wrong"
      end
      
    end
    f.close
    puts cnt
    true

    

  end

  def self.find_walkthroughs

    #ids =  [5936,5939,5944,5945,5946,5948,5951,5952,5979,5989,5993,6017]
#    (6011..6090).to_a.each do |y|
#      x = WebFigure.find(y)      
    f = open('walkthrough_features.lst','w')
    WebFigure.find(:all,:offset=>5000, :limit=>1000).each do |x|


      begin      
        w = WebPage.new(x)
        wt =  w.is_walkthrough?
        puts "#{x.id} #{wt.join(' ')} #{w.url}"
        f.puts "#{x.id} #{wt.join(' ')} #{w.url}"
        
        rescue
        puts "something wrong"
      end
     
    end
    f.close
    true
  end

end
