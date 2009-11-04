class Movie < ActiveRecord::Base

  has_one :photo, :as => :photoable  

  include Photoable
  
  def self.batch_import_from_input_file(input_file)
    File.open(input_file) do |f|
      f.readlines[2..-1].each do |x|
        path, *title = x.split
        title = title.join(' ')        
        puts "importing #{path} #{File.exists? path}"          
        Movie.create :title => title, :photo_file => path
      end
    end
    true
  end
  

  
end
