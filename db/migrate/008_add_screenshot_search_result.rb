class AddScreenshotSearchResult < ActiveRecord::Migration
  def self.up
    add_column :screenshots, :search_result, :text
  end

  def self.down
    remove_column :screenshots, :search_result
  end
end
