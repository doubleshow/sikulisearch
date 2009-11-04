class ScreenshotController < ApplicationController
  active_scaffold :screenshot do |config|
    config.list.columns = [:id, :large_lazy_photo, :keyword_edit, :labels, :knns] #:search_result]
    config.list.per_page = 50
    #config.list.sorting = {:id => :desc }
    config.actions = [:list]      
  end
  
  
  def list_selected_photos
    @screenshots = Screenshot.find(:all).select {|x| x.labels.size > 0}[0..499]        
  end
  
  def list_selected_keywords
    @screenshots = Screenshot.find(:all).select {|x| x.labels.size > 0}[0..499]        
  end
  
  
  def query
    if request.post?    
      @query = Query.create params[:query].merge({:source=>'screenshot/xp'})
      logger.info @query   
      redirect_to :action => 'query_result', :id => @query.id
    
    elsif request.get?
    
      @recent_queries = Query.find(:all, :limit => 10, :order => "created_at DESC")
    end        
  end
  
  def remote_query
    if request.post?
    
      @query = Query.create params[:query].merge({:source=>'screenshot/xp'})
      logger.info @query
    
      #responds_to_parent do
        #render :update do |page|
#          @queries = Query.paginate :per_page => 25, :order => 'id desc', :conditions => ['dataset = ?','butterfly'],
#                :page => params[:query_page]  
#          page.replace_html 'queries', :partial => "queries"  
        #end
      #end
      render :text => @query.id
    end    
  end
  
  def query_result
    @query = Query.find(params[:id])
    
    if @query.result_ids.nil?
      @query.match! 'xp'     
    end
    

    # Store results as an array of hashs
    # Eash hash contains two fields:
    #    1. :photo
    #    2. :text (html)
    # 
    # Assuming we have called search! to grab urls from Yahoo and saved the formatted
    # result in search_result, we can simply set :text to whatever is in search_result
    @results = []
    
    @query.result_ids.each do |photo_id|
      
      # get the screenshot associated with the photo id
      screenshot = Photo.find(photo_id).photoable      
      
      @results << {:photo => screenshot.photo, :text => screenshot.search_result}
      end    
  end



  def add_label
    @labelable = Screenshot.find params[:id]
    @labelable.labels = (@labelable.labels << params[:label].to_i).uniq
    @labelable.save
    
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace "labelable-#{@labelable.id}-labels", :partial => "labels"
          page.replace "labelable-#{@labelable.id}-knns", :partial => "knns"          
        end
      end
    end
  end
    
  def remove_label
    @labelable = Screenshot.find params[:id]
    @labelable.labels.delete(params[:label].to_i)
    @labelable.save
    
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace "labelable-#{@labelable.id}-labels", :partial => "labels"
          page.replace "labelable-#{@labelable.id}-knns", :partial => "knns"                    
        end
      end
    end
  end


  def keyword_edit
    screenshot = Screenshot.find params[:id]
    screenshot.keywords = params[:keywords].split
    screenshot.save
    
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace "screenshot_keyword_edit_#{screenshot.id}", :partial => "keyword_edit", :locals => {:screenshot => screenshot}
        end
      end
    end    
  end

  def keyword_search
    @screenshot = Screenshot.find params[:id]
    @screenshot.match_by_keywords
    @labelable = @screenshot
    respond_to do |format|
      format.js do
        render :update do |page|
          page.replace "labelable-#{@labelable.id}-knns", :partial => "knns"
        end
      end
    end    
  end


end
