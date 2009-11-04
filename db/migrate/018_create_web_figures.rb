class CreateWebFigures < ActiveRecord::Migration
  def self.up
    create_table :web_figures do |t|
      t.string 'pageurl'
      t.string 'imageurl'
      t.timestamps
    end
  end

  def self.down
    drop_table :web_figures
  end
end
