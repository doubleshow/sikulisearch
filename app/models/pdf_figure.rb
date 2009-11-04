class PdfFigure < ActiveRecord::Base
  
  has_one :photo, :as => :photoable  
  
  belongs_to :pdf_page

  include Photoable

  def label
    labels, refs = pdf_page.extract_labels_and_refs

    if not labels.keys.empty?
      labels[labels.keys[0]]
    else
      nil
    end

  end

  def ref
    labels, refs = pdf_page.extract_labels_and_refs

    x = labels.keys[0]
    

    return nil if x.nil?
    
    return refs[x] if refs.has_key? x
    
    tmp, prev_refs = pdf_page.prev.extract_labels_and_refs
    return prev_refs[x] if prev_refs.has_key? x

    tmp, next_refs = pdf_page.next.extract_labels_and_refs
    return next_refs[x] if next_refs.has_key? x

    return nil

  end
     
  def import_ocr_result
    ocr_result_file_path = "/csail/vision-trevor7/tomyeh/ebooks/pdf_figures/ocr/#{'%0.5d' % photo.id}.txt"    
    self.ocr = File.open(ocr_result_file_path ).read
    self.save    
  end
  
end
  
