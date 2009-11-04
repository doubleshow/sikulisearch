module VideoSegmentHelper
  
 
  def start_frame_number_column(record)
    frame  = record.start_frame
    frame.number.to_s + "<br>" + image_tag(frame.photo.url(:thumb))
  end
  
 
  def end_frame_number_column(record)
    frame  = record.end_frame
    frame.number.to_s + "<br>" + image_tag(frame.photo.url(:thumb))
  end
  
end
