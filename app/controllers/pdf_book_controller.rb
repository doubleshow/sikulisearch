class PdfBookController < ApplicationController
  active_scaffold :pdf_book do |config|
    config.list.columns = [:id, :title, :pages]
    config.list.sorting = {:id => :desc }
    config.search.columns = [:title]    
    config.actions = [:list]      
  end

  def books
     @book_titles = PdfBook.find(:all).map {|x| x.title}
  end
   

  def compare
    good_examples = [709,822,733,807,634,659,
      770,816,648,804,805,708,705,680,684,649,
      639,640,641,608]
    @queries = good_examples.map do |x|
      Query.find(x)
    end
     @queries.compact!
  end
  
  def compare_result
    @query = Query.find(params[:query_id])   
    @query_terms = params[:search_terms].downcase.split    

    @size = :medium
    @matched_pdf_figures = {}  
    photo_ids, @query_ocr = @query.match_by_ocr
    
    def filter(photo_ids)      
      figures = photo_ids.map {|x|
        pdf_figure = Photo.find(x).photoable
        if @query_terms.size == 0 or @query_terms.any? {|x| pdf_figure.pdf_page.pdf_book.title.downcase.include? x}
          pdf_figure
        else
          nil
        end
        
      }.compact
      figures
    end

    
    #@matched_pdf_figures[:ocr] = photo_ids.map {|x| Photo.find(x).photoable}
    @matched_pdf_figures[:ocr] = filter(photo_ids)#.map {|x| Photo.find(x).photoable}
    #@matched_pdf_figures[:vision] = @matched_pdf_figures[:ocr]
    @matched_pdf_figures[:vision] = filter(@query.match('pdf'))
    
               
  end
  
  def keyword_query_remote
    search_terms = params[:search_terms].downcase.split('+')
    
    pdf_page_ids = PdfPage.search_ferret(search_terms.join(' '))
    
    render :text => pdf_page_ids.join(',')    
  end
 
  def exhibit
    #@query_photo = Photo.find(85129)#Query.find(1196)
    
    query = Query.find(1196)#(1189)
    @query_photo = query.photo

    photo_ids = query.match  
    result = Result.new(photo_ids[0..9])
    
    json_localpath = "public/#{query.id}.json"
    @json_url = "/#{query.id}.json"
    result.write(json_localpath)

    render :layout => false
end
  
  def query_remote
    

    
    @query = Query.create params[:query].merge({:source=>'screenshot/study'})    
    @query_terms = params[:search_terms].downcase.split
    
    #photo_ids = @query.match('pdf')    
    photo_ids, query_ocr = @query.match_by_ocr
    pdf_figures = photo_ids.map {|x| Photo.find(x).photoable}
    pdf_pages   = pdf_figures.map {|x| x.pdf_page}
    pdf_pages.delete_if {|pdf_page| 
      not (@query_terms.size == 0 or @query_terms.any? {|x| pdf_page.pdf_book.title.downcase.include? x})
    }
    
    
      
    pdf_page_ids = pdf_pages.map{|x| x.id}
    
    render :text => pdf_page_ids.join(',')
  end

  def web
    
    if params[:keywords] 
      session[:keywords] = params[:keywords].split
    else
      session[:keywords] = nil
    end
    
    
    @query_photo = Photo.find(85129)#Query.find(1196)
    #@web_figures = WebFigure.find(:all,:limit=>10)    
 

    @photos = [] 
    @photos = @photos + [85109,85051,85129,85091,85063,85077].map {|x| Photo.find(x)}
    @photos = @photos[0..1]
    @photos = @photos + [22860,44263,35545,22860,17216,17314,65686,39150,44264,33631,33582].map{|x| PdfFigure.find(x).photo}
    @photos 
  end

  def amt
    render :text => params.inspect
  end

  def web_debug
    @web_figures = WebFigure.find(:all,:limit=>3)
  end

  def result
    @query = Query.find(params[:query_id])
    
    pdf_figure_ids = @query.match  
    @results = pdf_figure_ids.map do |x|
      
      pdf_figure = PdfFigure.find(x)
      pdf_page   = pdf_figure.pdf_page
      pdf_book   = pdf_page.pdf_book
      
          
       {:figure => pdf_figure, :book => pdf_book, :page => pdf_page}
    
   end.compact

  
  end
  
  def query_result
    
    @query = Query.find(params[:query_id])
    @query_terms = params[:search_terms]
        
    pdf_figure_ids = @query.match  
    #pdf_figure_ids = [266, 274, 215, 156, 271, 171, 179]
    
    
    @results = photo_ids.map do |x|
      
      # HACK: filter out obviously too small images
#      c = `identify #{photo.local_path}`
#      w,h = c.split(' ')[2].split('x').map{|x|x.to_i}      
#      if w < 100 || h < 100
#        nil
#      else
      
      
      pdf_figure = Photo.find(x).photoable
      pdf_page   = pdf_figure.pdf_page
      pdf_book   = pdf_page.pdf_book
      
      # filter book titles based on specified search terms
      if @query_terms.nil? or @query_terms.size == 0 or @query_terms.downcase.split.any? {|x| pdf_book.title.downcase.include? x}
        
      
       {:figure => pdf_figure, :book => pdf_book, :page => pdf_page}
      end
       

   end.compact

  end
  
  def select_page
    pdf_figure = PdfFigure.find(params[:figure_id])
    
    render :update do |p|
      p.replace_html :page_image, :partial => "page_image", :locals => {:page => pdf_figure.pdf_page}
      p.replace_html :figure_image, :partial => "figure_image", :locals => {:figure => pdf_figure}      
    end
    
  end
  
  def examples
    good_examples = [822,733,807,634,659,
      770,816,648,804,805,708,705,680,684,649,
      639,640,641,608]
    @queries = good_examples.map do |x|
      Query.find(x)
    end
  end
  
  def query
    good_examples = [709,822,733,807,634,659,
      770,816,648,804,805,708,705,680,684,649,
      639,640,641,608]
    @queries = good_examples.map do |x|
      Query.find(x)
    end
#     @queries = []
#     25.times do 
#       @queries << Query.find(:first, :offset => rand(Query.count), :conditions => ["source = ?", 'screenshot/xp'])
#     end    
     
     @queries.compact!
     

    
#      @recent_queries = Query.find(:all, :limit => 25, :order => "created_at DESC")
  end
  
end
