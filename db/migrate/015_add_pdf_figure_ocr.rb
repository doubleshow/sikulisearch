class AddPdfFigureOcr < ActiveRecord::Migration
  def self.up
    add_column :pdf_figures, :ocr, :text
  end

  def self.down
    remove_column :pdf_figures, :ocr
  end
end
