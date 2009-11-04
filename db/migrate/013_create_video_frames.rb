class CreateVideoFrames < ActiveRecord::Migration
  def self.up
    create_table :video_frames do |t|
      t.integer "video_id"
      t.integer "number"
      t.float   "start_second"
      t.float   "end_second"      
    end
  end

  def self.down
    drop_table :video_frames
  end
end
