module PdfFigureHelper
  
  def page_number_column(record)
    record.pdf_page.number
  end     
  
  def book_title_column(record)
    record.pdf_page.pdf_book.title
  end
  
  def ocr_column(record)
    "<pre>#{record.ocr}</pre>"    
  end
end
