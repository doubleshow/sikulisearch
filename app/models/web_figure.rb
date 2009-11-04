class WebFigure < ActiveRecord::Base
  
  has_one :photo, :as => :photoable  
  
  include Photoable

  require 'rubygems'
  #require 'YAML'

  def self.export_files
    Photo.find_all_by_photoable_type('WebFigure').each_with_index{|p,i|
      puts i
      `cp #{p.local_path(:original)} /cygdrive/f/screenshots/#{p.id}.jpg`
    }


  end

  def self.export
    f1 = open('webfigure_url.lst','w')
    f2 = open('webfigure_id.lst','w')

    Photo.find_all_by_photoable_type('WebFigure').each_with_index{|p,i|
#    WebFigure.find(:all).each_with_index {|x,i|
      puts i
      f1.puts "http://poq.csail.mit.edu:3100#{p.url(:original)}" 
      f2.puts "#{p.id} http://poq.csail.mit.edu:3100#{p.url(:original)}" 
    }
    f1.close
    f2.close
  end

  def self.save_all_urls
    f = File.open('urls.lst','w')
    WebFigure.find(:all).each {|x|
      f.puts x.pageurl
    }
    f.close
  end

  def self.count_urls
    count = {}
    open('urls.lst').each_line {|x|
      x.match(/http:\/\/(.*?)[\/$]/)
      host = $1
      count[host] = (count[host] || 0) + 1 unless host.nil?
      #puts host
    }

    f = open('url_counts.lst','w')
    pairs = []
    pairs = count.map {|x,y| [x,y]}
    pairs.sort!{|x,y| 
      y[1] <=> (x[1] + (x[0] < y[0] ? 0.5 : -0.5))
    }

    pairs.each { |x,y|
      #puts "#{x} #{y}"
      f.puts "#{x} #{y}"
    }
    f.close
     

    true
  end

  def self.import_bing#(dir='.')

    #items = 

    dir = "/home/tomyeh/research/sikuli-search/tineye/bing/done.12"

    items = YAML::load(open("#{dir}/index.yaml"))
    tbl = {}
    items.each do |item|
      tbl[item[:id]] = item
    end

    pngs = Dir.glob("#{dir}/png/*")
    pngs.each_with_index do |x,i|
      
      pattern = /png\/(\d*)\.png/
      m = x.scan(pattern)[0]

      print "(#{i+1}/#{pngs.size}) importing #{x} ... "

      if m
        id = m[0]
        html_src = x.sub(pattern, "html/#{$1}.html")
        item = tbl[id.to_i]
      
        if File.exists? html_src


          w = WebFigure.create :photo_file => x, :imageurl => item[:img], 
            :pageurl => item[:url]
          
          html_dest = "public/webpages/#{w.id}.html"
          `cp #{html_src} #{html_dest}`

          puts "done."
        else
          puts "html doesn't exist!"
        end
      else
        puts "animated gif skipped!"
      end

    end
    true
  end

  def self.import

    tbl = {}
    File.open('mac/index.lst').readlines.each do |x|
      id,w,h,imageurl,pageurl = x.split
      #tbl[id] = {:imageurl => imageurl, :pageurl => pageurl}
      tbl[imageurl] = id
    end

    WebFigure.find(:all).each do |x|
      
      id = tbl[x.imageurl]
      next if id.nil?
      cmd = "cp ~/research/sikuli-search/tineye/mac/html/#{id}.html public/webpages/#{x.id}.html"
      system cmd
    end

    # Dir.glob('mac/*').each do |x|
    #   id = File.basename(x,File.extname(x))
    #   y = tbl[id]
    #   If y
    #     Puts y[:imageurl]

    #     WebFigure.create :photo_file => x, :imageurl => y[:imageurl], 
    #     :pageurl => y[:pageurl]
    #   end
    # end

    nil

  end

  def webpage_url
     "webpages/#{id}.html"
  end

  def webpage_localpath
     "public/webpages/#{id}.html"
  end

  def webpage_text_localpath
    "public/webpages/#{id}.txt"
  end
  
  def open
    `cygstart public/webpages/#{id}.html`
  end

  def webpage_text
    File.open("tmp.html","w") {|f| 
      f.print webpage_html.gsub(/(alt=['"]?(\w* ?)+['"]?)/im,'')}
    `lynx -dump tmp.html`
    #`lynx -dump #{webpage_localpath}`
  end

  def self.delete_web_figures_without_html
    WebFigure.find(:all).each {|w|
      if not File.exists? w.webpage_localpath
        puts w.webpage_localpath
        w.destroy
      end
    }
  end

  def self.generate_html_txt
    WebFigure.find(:all).each {|web_figure|
        html = File.open(web_figure.webpage_localpath).read 
        File.open("tmp.html","w") {|f| 
          f.print html.gsub(/(alt=['"]?(\w* ?)+['"]?)/im,'')
      }
      puts web_figure.id
      `lynx -dump tmp.html > #{web_figure.webpage_text_localpath}`
    }
  end


  def self.generate_html_txt
    WebFigure.find(:all).reverse[20000..-1].each {|web_figure|

      if not File.exists? web_figure.webpage_text_localpath

        html = File.open(web_figure.webpage_localpath).read 
        File.open("tmp.html","w") {|f| 
          f.print html.gsub(/(alt=['"]?(\w* ?)+['"]?)/im,'')
        }
        puts web_figure.id
        `lynx -dump tmp.html > #{web_figure.webpage_text_localpath}`
      end
    }
  end


end
  
