class VideoSegmentController < ApplicationController
  active_scaffold :video_segment do |config|
    config.list.columns = [:id, :start_frame_number, :end_frame_number]
    config.list.sorting = {:id => :desc }
    config.actions = [:list]      
  end
end
