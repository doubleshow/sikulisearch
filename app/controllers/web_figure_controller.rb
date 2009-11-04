class WebFigureController < ApplicationController
  active_scaffold :web_figures do |config|
    config.list.columns = [:id, :lazy_photo, :pageurl, :imageurl]
    config.list.sorting = {:id => :desc }
  end  
end
