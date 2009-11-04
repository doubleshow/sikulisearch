class PdfPageController < ApplicationController
  active_scaffold :pdf_page do |config|
    config.list.columns = [:id, :pdf_book, :number, :text, :figures]
    config.list.sorting = {:id => :desc }
    config.actions = [:list]     
#    config.search.columns = [:title]    
  end



  def image_url
    @pdf_page = PdfPage.find(params[:id])
    render :text => "http://poq.csail.mit.edu:3000#{@pdf_page.image_url}"
  end




end
