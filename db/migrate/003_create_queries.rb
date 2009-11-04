class CreateQueries < ActiveRecord::Migration
  def self.up
    create_table :queries do |t|
      t.string  "source"
      t.string  "result_ids"
      t.string  "target_ids"
      t.timestamps
    end
  end

  def self.down
    drop_table :queries
  end
end
