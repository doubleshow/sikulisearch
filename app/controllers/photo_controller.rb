class PhotoController < ApplicationController
 active_scaffold :photo do |config|
    config.list.columns = [:id, :image, :width, :height, :photoable_type]
    config.list.sorting = {:id => :desc }
  end
end
