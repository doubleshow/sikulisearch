module PhotoHelper
  def image_column(record)
    image_tag(photo.url(:original), :height => '200')
  end    
end
