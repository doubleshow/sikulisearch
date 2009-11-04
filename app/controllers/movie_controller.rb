class MovieController < ApplicationController
  active_scaffold :movie do |config|
    # define my own photo column 'lazy_photo' so active record would not 
    # pre-load the photo association by extremely slow outter join operation        
    config.list.columns = [:id, :lazy_photo, :title]
    config.list.sorting = {:id => :desc }
    config.search.columns = [:title]    
  end
end
