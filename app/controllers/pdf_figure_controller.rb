class PdfFigureController < ApplicationController
  active_scaffold :pdf_figure do |config|
    config.list.columns = [:id, :lazy_photo, :book_title, :page_number, :ocr]
    config.list.sorting = {:id => :desc }
  end


  def bad
    
    @bads = (6905..10587).map {|x| PdfFigure.find(x) if PdfFigure.exists?(x)}.compact.select {|x| x.ocr.size <= 1 }
    
#    goods = [1027,1874,1884,2192,2336,2487,2488]
    
#    @bads = PdfFigure.find(:all).select {|x| x.ocr.size <= 1 and (not goods.include?(x.id))}
      
    if params[:delete] == 'yes'
      @bads.each {|x| x.destroy}            
      @bads = []      
    end


  end
  
   def show_figures
     @figures = [123,1250,124,117,130,1509,937,1549,942,1510,513].map {|x| PdfFigure.find(x)}
   end


  def view
    @figure = PdfFigure.find(params[:id])
  end
  
end