module PdfPageHelper
  def text_column(record)
    "<pre>" + record.text + "</pre>" unless record.text.nil?
  end
  
  
  def figures_column(record)
    
    record.pdf_figures.map do |x|
      "<img src=#{x.photo.url}><br>"
    end
    
    
  end
end
