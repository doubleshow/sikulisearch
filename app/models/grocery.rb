class Grocery < ActiveRecord::Base
  has_one :photo, :as => :photoable  

  include Photoable
  
    def self.batch_import_from_input_file(input_file)
    File.open(input_file) do |f|
      f.readlines[6..-1].each do |x|
        path, *rest = x.split
        name = rest.join(' ')        
        puts "importing #{path} #{File.exists? path}"          
        Grocery.create :name => name, :photo_file => path
      end
    end
    true
  end
  
end
