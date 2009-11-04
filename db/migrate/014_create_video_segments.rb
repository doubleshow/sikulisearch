class CreateVideoSegments < ActiveRecord::Migration
  def self.up
    create_table :video_segments do |t|
      t.integer "start_frame_id"
      t.integer "end_frame_id"
    end
  end

  def self.down
    drop_table :video_segments
  end
end
