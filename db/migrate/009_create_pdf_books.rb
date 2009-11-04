class CreatePdfBooks < ActiveRecord::Migration
  def self.up
    create_table :pdf_books do |t|      
      t.string  "title"      
      t.string  "isbn"
      t.integer "pages"
      t.string  "source_file"
      t.integer "cover_photo_id"     
      t.timestamps
    end
  end

  def self.down
    drop_table :pdf_books
  end
end
