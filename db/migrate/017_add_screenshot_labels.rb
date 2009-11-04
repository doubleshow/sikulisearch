class AddScreenshotLabels < ActiveRecord::Migration
  def self.up
    add_column :screenshots, :labels, :string
    add_column :screenshots, :knns, :string
  end

  def self.down
    remove_column :screenshots, :labels
    remove_column :screenshots, :knns
  end
end
