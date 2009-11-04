#
# allow automatic photo creation by a single call to Photoable.create
# 
# e.g., 
#
# Book.create :photo_file => 'book_cover.jpg', :title => 'Ruby for dummy'
#
module Photoable

    
  def photo_file=(photo_file)
    @photo_file = photo_file
  end   
  
  def photo_file
    @photo_file
  end
   
  def after_destroy
    self.photo.destroy unless photo.nil?
  end
   
  def after_create
    Photo.create :file => photo_file, :photoable_type => self.class.name, :photoable_id => self.id                 
  end
  
end