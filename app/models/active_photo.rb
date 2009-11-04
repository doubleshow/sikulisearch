module ActivePhoto
  
  # The directory structure for saving photos is organized by 
  # groups of 1000 photos. The name of the sub-directory holding
  # a group of 1000 photos is the lowest id of the images in it.
  #
  # For example,
  # 
  # 0 : 00001 - 01000
  # 1 : 01001 - 02000
  # 2 : 02001 - 03000
  #
  #
  # The location of various versions of the photos that will be 
  # automatically created and saved are:
  #
  #
  # normal     0/00001.jpg         400
  # original   0/o/00001.jpg      
  # medium     0/m/00001.jpg       150
  # thumb      0/t/00001.jpg       75
  #
  #
  # We assume the normal version is the size of the photo that
  # will be most often used for the purpose of matching.
  #
  #
  # Beyond the first 100,000 images
  #
  # The naming scheme becomes whatever the image id is
  #
  # 12345/12345001.jpg
  # 12345/12345002.jpg
  #
  
  
  def format
    "jpg"   
  end
  
  def local_root
    "public/photos"
  end
  
  def url_root
    "/photos"
  end
  
  
  def basename(version = :normal)    
    name = "%0.5d.%s" % [id, format]
    case version
    when :original
        "o/" + name
    when :thumb
        "t/" + name        
    when :medium
        "t/" + name
    when :normal
      name
    end
  end    
  
  def url(version = :normal )    
    [url_root, sub_directory, basename(version)].join('/')
  end
  
  def local_path(version = :normal)
    [local_root, sub_directory, basename(version)].join('/')
  end
  
  
  def sub_directory
   ((id-1) / 1000).to_s      
  end
  
  
  # Set the location of the temporary file holding
  # the image data of this photo
  # or the path to the image file in the local filesystem
  def file=(incomming_file)
    @file = incomming_file
  end  
  
  def file
    @file
  end
  
  #  puts "I#{@image}"
  #  puts @image.columns
  #  puts @image.rows
  #  @image.columns > 10 and @image.rows > 10
  #  #      puts @images
  #  #      errors.add("photo_file","images too small")
  #  #    end
  #end
  
  
  # RMagick module for resizing photos
  #require 'RMagick'  
  #include Magick
  
  # For reading image from an URL
  require 'net/http'
  
  
  def load_image
    
    logger.info "The value of the file parameter is:#{@file}"
    logger.info "The class of the file parameter is:#{@file.class}"
    
    if @file.class == String      
      image_path = @file        
    elsif @file.class == Tempfile
      image_path = @file.path
    elsif @file.class == ActionController::UploadedTempfile  
      image_path = @file.path
    elsif @file.class == File
      image_path = @file.path
    elsif @file.class == ActionController::UploadedStringIO
      
      # writing the data held by ActionController::UploadedStringIO to
      # a temporary file
      image_path = ''
      Tempfile.open('active_photo') do |tmp|
        tmp.write(@file.read)
        image_path = tmp.path
      end               
    end
    
    # if imgpath is a web address, 
    if /http/.match(image_path)
      response = Net::HTTP.get_response URI.parse(image_path)
      
      case response
      when Net::HTTPSuccess 
        Tempfile.open('active_photo') do |tmp|
          tmp.write(response.body)
          image_path = tmp.path
        end
      else
        # raise an error if http get fails
        response.error!
      end    
      
      
    end
    
    if image_path.nil?
      raise 'image_path can not be nil'
    elsif image_path == ''
      raise 'image_path can not be empty'
    else
      
      @image_path = image_path
      # read from file
      #imgs = Magick::Image.read(image_path)
      
      # look at only the first image
      # @image = imgs[0]
      #logger.info @image
    end
    
  end
  
  
  
  # Create copies of images of different dimensions
  # this must be done after the record is created so we can
  # name the created images after the photo ids
  def after_create
    
    load_image
    
    ## change the format
    ## @image.format = format
    
    # save the original
    #mywrite(@image, local_path(:original))
    # save as jpg
    #`convert #{@image_path} #{local_path(:original)}`
    #create_copy @image_path, local_path(:original)
    
    # save different versions of the image
    versions = {:original => nil, :normal => 400, :thumb => 150}              
    versions.each do |version, size|        
      
      create_copy(@image_path, local_path(version), size)
      #mywrite(img1, local_path(version))                
    end            
    
  end
  
  # remove the images from disk after the photo is deleted
  def after_destroy    
    [:normal, :thumb, :original].each do |x|
      File.unlink local_path(x) if File.exists? local_path(x)
    end   
  end
  
  private  
  
  # write an image to file
  #def mycopy(src,dest)    
    
    # create directories if necessary
    
    #obj.write(filename)    
   # `convert #{src} #{dest}`
  #end
  
  # helper function that resizes an image to fit in 
  # a 'd' by 'd' square area
  def create_copy(src,dest,size)

    if not File.exists? File.dirname(dest)      
      FileUtils.mkdir_p File.dirname(dest)
    end
    
    if size
      `convert -thumbnail '#{size}x#{size}>' #{src} #{dest}`
    else
      `convert #{src} #{dest}`
    end
  end
  
end
