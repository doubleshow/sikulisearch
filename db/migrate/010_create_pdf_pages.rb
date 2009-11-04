class CreatePdfPages < ActiveRecord::Migration
  def self.up
    create_table :pdf_pages do |t|      
      t.integer "number"
      t.integer "pdf_book_id"
      t.text    "text"
      t.timestamps
    end
  end

  def self.down
    drop_table :pdf_pages
  end
end
