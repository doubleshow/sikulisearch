class SearchController < ApplicationController

  def amt
    @amt = true
    id = params[:id]
    name,query_id = id.split('-')
    query = Query.find(query_id)
    @query_photo = query.photo    
    @json_url = "/amt/#{id}.json"
    
    render :action  => 'exhibit', :layout => false
  end

  def upload
    if request.post?    
      @query = Query.create params[:query].merge({:source=>'upload'})
      photo_ids = @query.match
      @photos = photo_ids.map {|x| Photo.find(x) if Photo.exists?(x)}.compact

      redirect_to :action => 'matched_photos'
    
    elsif request.get?
    
      @recent_queries = Query.find(:all, :limit => 10, :order => "created_at DESC")
    end        

  end

  def query
      @query = Query.find(params[:id])
      photo_ids,votes = @query.match
      
    mask = photo_ids.map {|x| Photo.exists?(x)}

    @photos = photo_ids.zip(mask).select{|x| x[1]}.map{|x| Photo.find(x[0])}
    @votes  = votes.zip(mask).select{|x| x[1]}.map{|x| x[0]}
    
#      @photos.zip(votes).select {|x| 
      
      render :action => 'matched_photos'
  end

  def amt_label

    id = params[:id]
    query = Query.find(id)
    @query_photo = query.photo
    @another_query_photo = Query.find(id.to_i+1).photo

    photo_ids,votes = query.match

    @photos = photo_ids.slice(0,15).map{|x| Photo.find(x) if Photo.exists?(x)}.compact
    @matches = @photos.slice(0,10).map {|x| [x,:u]}

    @matches << [@matches.rand[0], :u]
    @matches << [@query_photo, :g]
    @matches << [@another_query_photo, :b]
    @matches.shuffle!    

  end

  def example
    query = Query.find(1197)
    @query_photo = query.photo

    @example = true

    render :action => 'exhibit', :layout => false
  end

  def exhibit
    @amt = false
    id = params[:id]

    query = Query.find(id)
    @query_photo = query.photo

    photo_ids,votes = query.match

    photo_ids = photo_ids.slice(0,20)

    json_localpath = "public/#{query.id}.json"
    @json_url = "/#{query.id}.json"

    result = Result.new
    result.add_by_photo_ids(photo_ids)

    #result.pages.slice!(0,10)   
    #result.sort(['system','preferences'])
    result.save_exhibit(json_localpath)


    render :layout => false
  end


end
