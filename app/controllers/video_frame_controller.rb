class VideoFrameController < ApplicationController
  active_scaffold :video_frame do |config|
    config.list.columns = [:id, :lazy_photo, :number, :start_second, :end_second]
    config.list.sorting = {:id => :desc }
    config.actions = [:list]      
  end
end
