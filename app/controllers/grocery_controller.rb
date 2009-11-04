class GroceryController < ApplicationController
  active_scaffold :grocery do |config|
    # define my own photo column 'lazy_photo' so active record would not 
    # pre-load the photo association by extremely slow outter join operation        
    config.list.columns = [:id, :lazy_photo, :name]
    config.list.sorting = {:id => :desc }
    config.search.columns = [:name]    
  end
end
