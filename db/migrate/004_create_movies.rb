class CreateMovies < ActiveRecord::Migration
  def self.up
    create_table :movies do |t|
      t.text    "title"
      t.timestamps
    end
  end

  def self.down
    drop_table :movies
  end
end
