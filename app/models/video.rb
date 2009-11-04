class Video < ActiveRecord::Base
  
  has_many :video_frames
  
  def self.import_video
    title = 'camstudio'
    input_dir = 'camstudio/frames/'
    
    fs = Dir.glob("#{input_dir}/*.jpg")
    
    # "camstudio349.jpg" => 349
    nos = fs.map {|x| /(\d+)/ =~ x; $1}
    
    # sort the order the input files by the frame numbers
    fss = fs.zip(nos).sort {|a,b| a[1].to_i <=> b[1].to_i}
    
    fss.each {|f| 
      #puts f[0]
      file,no = f
      #no = f[1]
      puts no

       VideoFrame.create :number => no.to_i, :video_id => 1, :start_second => no.to_f, :end_second => no.to_f + 1, :photo_file => file
      }
    
    
  end
  
  def self.import_video_segments
    
    title = 'camstudio'
    input_dir = 'camstudio/keyframes/'
    
    
    
    fs = Dir.glob("#{input_dir}/*.bmp")
    
    nos = fs.map {|x| /(\d+)/ =~ x; $1.to_i}
    
    start_frame_numbers = nos.sort# {|x,y| x.to_i < y.to_i}
    
    last_frame_number = 439
    
    start_frame_numbers << last_frame_number + 2
   
    (0..start_frame_numbers.size-2).each do |i|
      
      start_frame_number = start_frame_numbers[i] - 1
      end_frame_number   = start_frame_numbers[i+1]-1 - 1 # compensate for 1-off mistake
      
      puts "%d -> %d" % [start_frame_number, end_frame_number]
      
      start_frame = VideoFrame.find_by_video_id_and_number 1, start_frame_number
      end_frame   = VideoFrame.find_by_video_id_and_number 1, end_frame_number
            
      VideoSegment.create :start_frame_id => start_frame.id, :end_frame_id => end_frame.id
      
    end
      
          
  end
  
end
