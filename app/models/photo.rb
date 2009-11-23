class Photo < ActiveRecord::Base

  belongs_to :photoable, :polymorphic => true
  
  include ActivePhoto

  def self.export
    
    Photo.find_all_by_photoable_type("WebFigure").each {|p| 
      puts "#{p.id} #{p.local_path}"
      `cp #{p.local_path} export/#{p.id}.jpg`
    }
    true
  end

  def self.lowres
    Photo.find_all_by_photoable_type("WebFigure").each {|p| 
      puts "#{p.id} #{p.local_path}"
      `convert -quality 40 export/#{p.id}.jpg lowres/#{p.id}.jpg`
    }
    true
  end

  def self.thumb
    Photo.find_all_by_photoable_type("WebFigure").each {|p| 
      puts "#{p.id} #{p.local_path}"
      `convert -thumbnail '#{20}x#{20}>' lowres/#{p.id}.jpg thumb/#{p.id}.jpg`
    }
    true
  end
  
  def self.exportpdf
    Photo.find_all_by_photoable_type("PdfFigure").each {|p| 
      puts "#{p.id} #{p.local_path}"
      `convert #{p.local_path(:original)} -thumbnail '400x400>' -quality 40  lowrespdf/#{p.id}.jpg`
      `convert lowrespdf/#{p.id}.jpg -thumbnail '20x20>' thumbpdf/#{p.id}.jpg`
    }
    true
  end

  def self.exportquery
    Photo.find_all_by_photoable_type("Query").each {|p| 
      puts "#{p.id} #{p.local_path}"      
      `convert #{p.local_path(:original)} -thumbnail '400x400>' -quality 40  lowrespdf/#{p.id}.jpg`
      `convert lowrespdf/#{p.id}.jpg -thumbnail '20x20>' thumbpdf/#{p.id}.jpg`
    }
    true
  end


  def photoable
    Kernel.const_get(photoable_type).find(photoable_id)
  end

  def ocr
    require 'tempfile'  
    t = Tempfile.open('query')
    t.close
    tmp = t.path

    #temp_filename = '/tmp/3grams.bin'
    
    source_image = local_path(:original)
    tmp_pgm    = "#{tmp}.pgm"
    tmp_tif    = "#{tmp}.tif"
    tmp_txt    = "#{tmp}.txt"
    tmp_3grams = "#{tmp}.bin"
    
    # resize 
    `convert #{source_image} #{tmp_pgm}`
    #`convert -resize 200% #{source_image} #{tmp_tif}`
    `convert -resize 400% #{tmp_pgm} #{tmp_tif}`
    #`convert #{source_image} #{tmp_tif}`
    puts "tesseract #{tmp_tif} #{tmp_txt}"
    `tesseract #{tmp_tif} #{tmp_txt.gsub('.txt','')}`
    #extract_3grams(tmp_txt, tmp_3grams)          
    File.open(tmp_txt).readlines
  end
  
  def save_dimensions
    c = `identify #{local_path(:original)}`
    w,h = c.split(' ')[2].split('x').map{|x|x.to_i}      
    self.height = h
    self.width = w
    self.save
  end

end
