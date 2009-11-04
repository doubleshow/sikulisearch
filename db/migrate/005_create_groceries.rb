class CreateGroceries < ActiveRecord::Migration
  def self.up
    create_table :groceries do |t|
      t.text    "name"
      t.timestamps
    end
  end

  def self.down
    drop_table :groceries
  end
end
