class QueryController < ApplicationController
  active_scaffold :query do |config|
    # define my own photo column 'lazy_photo' so active record would not 
    # pre-load the photo association by extremely slow outter join operation        
    config.list.columns = [:id, :lazy_photo, :results, :source]
    config.list.sorting = {:id => :desc }
  end
end
