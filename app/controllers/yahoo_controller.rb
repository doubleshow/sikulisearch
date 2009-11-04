class YahooController < ApplicationController
  def index    
  end
  
  ##########
  def browse
  ##########  
  
   # randomly pick some query images
   @queries = []
   15.times do 
     @queries << Query.find(:first, :offset => rand(Query.count), :conditions => ["source != ?", 'screenshot/xp'])
   end
  
    #@queries = Query.find_all_by_source('n95/movie',:limit => 15, :order => 'id desc')
    render :update do |page|
      #page[:queries].hide
      
      page[:query_path].focus      
      
      page[:queries].replace :partial => 'queries'
      page[:queries].hide
      page.delay(1) do
        page.visual_effect :appear, :queries      
      end
    end    
  end
   
  ################
  def select_query
  ################  
    @query = Query.find(params[:id])
    @question = Question.new :query => @query
    
    # figure out the ground truth type from the source string
    # i.e., n95/movie => Movie
    n95, type = @query.source.split('/')
    type.capitalize!


    # randomly insert 10 images to thre result    
    matched_ids = []    
    
    # seed it to a predictable number, so the random result of each
    # query image is always the same
    srand(@query.id)
    
    # insert random images of the other types to the result
    @query.result_ids.each do |x| 
      matched_ids << x

      2.times do
      random_photo = Photo.find :first, :offset => (Photo.count * rand ).to_i
      while random_photo.photoable_type == type and random_photo.photoable_type == 'Screenshot'
        random_photo = Photo.find :first, :offset => (Photo.count * rand ).to_i            
      end      

      
      
      matched_ids << random_photo.id      
      end
    end

    @matched_photos = matched_ids.map {|x| Photo.find(x)}
    

    session[:matched_ids] = matched_ids
    
    render :update do |page|
      
      # update the filename in the query selection input field
      page[:query_path].value = "My Pictures/#{@query.photo.id}.jpg"      
      page[:query_id].value = "#{@query.id}" 
      
      # highlight the selected query photo
      page.visual_effect :highlight, "query#{@query.id}"
      
      # delay a bit, then fade out the query selection window
      page.delay(1) do
        page.visual_effect :fade, :queries
      end            
            
      # reset the content of the ask panel
      page[:ask].replace_html :partial => 'ask'

      # display the ask panel
      #page.delay(1) do
        page.visual_effect :appear, :ask
      #end
      
      # display the selected query photo
      page[:query_photo].replace_html :partial => 'query_photo'      
      
      # show the form for asking the question
      page[:ask_form].replace_html :partial => 'ask_form'
      

      # show the form for asking the question
      page.visual_effect :appear, :ask_form

      # bring the focus to the question input field
      page[:question_text].focus
      
    end    
  end
  
  ######################
  def suggest_categories
  ######################  
    
    @question = Question.new :text => params[:question_text], :query_id => params[:query_id]
    
    @suggested_categories = @question.suggest_categories
    session[:suggested_categories] = @suggested_categories
    @selected_category = {}
    
    
    @matched_photos = session[:matched_ids].map {|x| Photo.find(x)}
    
    @matched_photos_for_category = {}
    @suggested_categories.each do |category|      
      @matched_photos_for_category[category] = @matched_photos.select do |photo|       
       category[:models].any? {|x| x == photo.photoable_type}
      end[0..4]
    end
    
        
    session[:question] = @question
   
    render :update do |page|
      
      #page[:answer].replace :partial => 'answer'
      
      page[:automatic_answer].replace_html ''
      page[:suggested_categories].replace_html :partial => 'suggested_categories'      
#      page[:selected_photo].replace_html :partial => 'selected_photo'      
    end    
  end  
  
  
  ###################
  def select_category
  ###################  
    @selected_category = Book.category_find params[:id].to_i
  
    @filtered_knn_photos = session[:knn_ids].map do |id| 
      Photo.find(id)
    end.select do |photo|
      @selected_category[:models].include? photo.photoable_type
    end
    session[:knn_ids_filtered] = @filtered_knn_photos.map {|x| x.id}
    
    @selected_photo = @filtered_knn_photos.first
    
    book = Book.find(@selected_photo.photoable_id)    
    @answer = book.ask session[:question].text
    @knns = Book.associate_random_questions @filtered_knn_photos[0..3], session[:question].text


    render :update do |page|
      @suggested_categories = session[:suggested_categories]
      page[:suggested_categories].replace :partial => 'suggested_categories'


      page[:filtered_knn_photos].replace :partial => 'filtered_knn_photos'
      page[:automatic_answer].replace :partial => 'automatic_answer'      
      page[:selected_photo].replace_html :partial => 'selected_photo'
      page[:related_questions].replace :partial => 'related_questions'
    end    
  end
  
  ################
  def select_photo
  ################  
    @selected_photo  = Photo.find(params[:photo_id])
    @category = params[:category]
    #@filtered_knn_photos = session[:knn_ids_filtered].map {|x| Photo.find(x)}
    
#    book = Book.find(@selected_photo.photoable_id)    
#    @answer = book.ask session[:question].text
#    @knns = Book.associate_random_questions @filtered_knn_photos[0..3], session[:question].text

    item = @selected_photo.photoable

    @answer = item.ask session[:question].text
    
    render :update do |page|
      #page[:matched_photos].replace :partial => 'filtered_knn_photos'
      #page[:suggested_categories].replace :after, :partial => 'automatic_answer'
      page[:automatic_answer].replace_html :partial => 'automatic_answer'        
      page.delay(0.1) do
        page.visual_effect :slide_down, :automatic_answer
      end
      page[:selected_photo].replace_html :partial => 'selected_photo'
    end
    
  end

end
