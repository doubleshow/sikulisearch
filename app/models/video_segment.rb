class VideoSegment < ActiveRecord::Base

  def start_frame
    VideoFrame.find self.start_frame_id
  end
  
  def end_frame
    VideoFrame.find self.end_frame_id
  end
  
  

  def self.prepare_for_imgdb(output_dir)
  
      imagelist_filename = "#{output_dir}/imagelist.txt"
      
      f = File.open(imagelist_filename,'w')
       
       
       
      self.find(:all).each do |segment|
        
        x = segment.start_frame.photo        
        src  = x.local_path
        dest = "#{output_dir}/#{File.basename(src)}.pgm"        
       
        convert_command = "convert #{src} #{dest}"
        puts convert_command
        system convert_command
        
        id = segment.id  
        
        f.puts "#{dest} #{id}"
        
      end
      
      f.close
      
  end
    
end
