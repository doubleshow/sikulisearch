module PhotoableHelper
  def lazy_photo_column(record)
    if record.photo  
      "#{record.photo.id}<br>" +  
        link_to(image_tag(record.photo.url), record.photo.url(:original),:target=>'_blank')
    end
  end  
end
