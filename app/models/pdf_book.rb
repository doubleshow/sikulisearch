class PdfBook < ActiveRecord::Base
  
  
  has_many :pdf_pages

  # Example output of pdfinfo:
  #
  #  Creator:        Adobe Acrobat 8.1 Combine Files
  #  Producer:       Acrobat Distiller 4.0 for Macintosh
  #  CreationDate:   Sun Aug 24 00:44:36 2008
  #  ModDate:        Sun Aug 24 00:44:36 2008
  #  Tagged:         yes
  #  Pages:          224
  #  Encrypted:      no
  #  Page size:      595 x 419 pts
  #  File size:      7865480 bytes
  #  Optimized:      yes
  #  PDF version:    1.6
  
  def self.import(path)
    
    s = `pdfinfo  #{path}`
 
    # hash to collect parsed key-value pairs
    info = {}
    
    s.each do |line|
      key, *value = line.chomp.split ':'

      value = value.join(':').lstrip;
      
      #puts "#{key} => #{value}"
      info[key] = value      
    end
    
    pages = info['Pages']    
    #puts pages
    
    filename = File.basename(path)
    title,isbn,rest = filename.split('.')
    
    title = title.split('-').join(' ')
    
    puts "#{title}, #{pages} pages, ISBN = #{isbn}"
    

    self.create :title => title, :pages => pages, :isbn => isbn, :source_file => filename      
    #puts isbn
    
  end
  
  def self.import_from_directory(dirname)
    Dir.glob("#{dirname}/*.pdf").each do |f|
      import f
    end
  end
  
  def create_empty_pages
    (1..self.pages).each do |i|
      PdfPage.create :number => i, :pdf_book_id => self.id            
    end    
  end
  
  def self.create_empty_pages_all
    self.find(:all)[2..-1].each_with_index do |b,i|
      puts "processing book #{i}"
      b.create_empty_pages
    end
  end
  
  def self.extract_figures_all
    self.find(:all,:conditions => 'id > 10').each do |b|
      b.extract_figures
    end
    
  end
  
  def pdf_dir
    '/scratch2/mmdb2/pdfs'    
  end  
  
  def pdf_localpath
    "#{pdf_dir}/#{self.source_file}"
  end


  def self.convert_to_images_all
    PdfBook.find(:all).each do |book|
      puts "converting book #{book.id} : #{book.title}"
      book.convert_to_images
    end
    
  end
  
  def convert_to_images
    rootdir = '/scratch2/mmdb2/pdf_images'
    destdir = "#{rootdir}/#{id}"
    Dir.mkdir(destdir) unless File.exists?(destdir)
    cmd = "pdftoppm #{pdf_localpath} #{destdir}/#{id}"
    system cmd
    Dir.glob("#{destdir}/*.ppm") do |x|
      `convert -resize 75% -quality 50 #{x} #{x.sub('ppm','jpg')}`      
      `rm #{x}`
    end
  end

  def extract_figures
    #pdfdir = '/csail/vision-trevor7/tomyeh/ebooks/pdfsource'
    pdfdir = '/scratch2/mmdb2/pdfs'
    ppmdir = 'tmp'    

    (1..self.pages).each do |i|
      prefix = "#{ppmdir}/#{self.id}-page"

      cmd = "pdfimages -q -f #{i} -l #{i} #{pdfdir}/#{self.source_file} #{prefix}#{i}"
      #puts cmd    
      system cmd
      
      extracted_ppms = Dir.glob("#{prefix}*")
      
      if extracted_ppms.size > 0      
        #puts "extracted #{extracted_ppms.size} image(s) from page #{i} of book #{self.id}"
        
           page = PdfPage.find :first, :conditions => {:pdf_book_id => self.id, :number => i}
        cnt = 0       
        
        extracted_ppms.each do |ppm|
                    
        # call 'identify' to find the dimensions of the image
        # sample output:
        # test.jpg JPEG 262x400 262x400+0+0 DirectClass 8-bit 36.5703kb
        c = `identify #{ppm}`
        w,h = c.split(' ')[2].split('x').map{|x|x.to_i}
        
          if h > 20 and w > 20
            PdfFigure.create :pdf_page_id => page.id, :photo_file => ppm
            cnt = cnt + 1
          end
        end
        
        puts "book #{self.id} page #{i}, extracted #{extracted_ppms.size}, saved #{cnt}"        
        
        cmd = "rm #{prefix}*"
        #puts cmd
        system cmd        
      end
    end
    
    
    
    
  end
  
  
#  def self.export_flat
    
    
#  end
  
  def self.export
    
    outputdir = '/csail/vision-trevor7/tomyeh/pdfs'
    
    imgdbexe = '/csail/vision-trevor7/tomyeh/engine/bin/imgdb-exp.out'
    
    (21..102).map{|x|PdfBook.find(x)}.each do |b|
        
      bookdir = "#{outputdir}/#{b.id}"
      puts bookdir
      
      Dir.mkdir(bookdir) unless File.exists?(bookdir)
      
      #b.pdf_pages[0..100].each do |p|
      b.pdf_pages.each do |p|
        
        #puts p.id
        #puts p.number
                
        #pagedir = "#{bookdir}/#{p.number}"        
        pagedir = bookdir
        #pagetext = "#{pagedir}/content.txt"        
        
        
        Dir.mkdir(pagedir) unless File.exists?(pagedir)
        
        figures = p.pdf_figures
        
        if figures.size > 0
          
          puts pagedir
          #puts pagetext

          
          figures.each do |f|
            
            prefix = "#{pagedir}/#{f.id}"
            img = prefix + ".jpg"
            txt = prefix + ".txt"
            pgm = prefix + ".pgm"   
            pset = prefix + ".sift.pset"
            
            puts img
            puts txt
            
            
            `cp #{f.photo.local_path} #{img}`            
            `convert #{img} #{pgm}`
            `#{imgdbexe} extract #{pgm} #{pset}`
            
          end
        
        end
        
        
      end
    
    end
        
  end
  
  
end
