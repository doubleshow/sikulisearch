module PdfBookHelper

  def hk(text)
    keywords = session[:keywords]
    #keywords = ["system","preferences"]
    if keywords
      keywords.each_with_index do |keyword,i|
        
        text.gsub!(/(#{keyword})/mi){|s| 
          "<span class='highlight#{i}'>*#{s}*</span>"}

      end
    end
    text    
  end

end
