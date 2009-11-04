class VideoFrame < ActiveRecord::Base
  
  belongs_to :video
  has_one :photo, :as => :photoable  
  
  include Photoable
  
  
  
end
