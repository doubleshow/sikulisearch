module ScreenshotHelper
    include PhotoableHelper
    
  def keywords_column(record)
    record.keywords.join(' ')
  end    
  
  def search_result_column(record)
    record.search_result
  end
  
  
  def large_lazy_photo_column(record)
    if record.photo  
      "#{record.photo.id}<br>" +  
        link_to(image_tag(record.photo.url), record.photo.url(:original),:target=>'_blank')
    end    
  end
 
  
  def keyword_edit_column(record)
    render :partial => 'screenshot/keyword_edit', :locals => {:screenshot => record}          
  end
    
  def labels_column(record)
    @labelable = record      
    render :partial => 'screenshot/labels'      
  end
  
  def knns_column(record)
    @labelable = record      
    render :partial => 'screenshot/knns'
  end  
  
end
