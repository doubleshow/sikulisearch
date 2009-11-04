class Question < ActiveRecord::Base
  
    belongs_to :query
  
    ##########################
    def self.category_find(id)
    ##########################
      category_table[id]
    end
    
    #######################
    def self.category_table
    #######################
      categories = []
      categories << {:id => 1, :name=>'Product',:path=>'Product',:models=>['Book','Movie','Grocery'],
        :keywords => ['much','price']}
        
      categories << {:id => 2, :name=>'Entertainment',:path=>'Product/Entertainment',:models=>['Book','Movie'],
        :keywords => ['rating','rated','story','plot','funny']}
        
      categories << {:id => 3, :name=>'Book',:path=>'Product/Entertainment/Book',:models=>['Book'],
        :keywords => ['wrote','book','author','pages','read']}
        
      categories << {:id => 4, :name=>'Movie',:path=>'Product/Entertainment/Movie',:models=>['Movie'],
        :keywords => ['director','boxoffice','dvd','directed','movie','actor','actress']}
        
      categories << {:id => 5, :name=>'Grocery',:path=>'Product/Grocery',:models=>['Grocery'],
        :keywords => ['weight','recipe','cereal','chips']}
        
      categories << {:id => 6, :name=>'Landmark',:path=>'Landmark',:models=>['Landmark'],
        :keywords => ['building','build','architect','where','location','place']}
      
      # build a table, using id as key
      table = {}
      categories.each do |category|
        table[category[:id]] = category
      end
      table 
    end
    
    ######################
    def suggest_categories
    ######################
      categories = Question.category_table.values

      scores = categories.map do |category|
        score = 0
        category[:keywords].each do |keyword|
          if self.text.downcase =~ /#{keyword}/
            score = score + 1
          end          
        end
        score
      end      

      suggested_categories = categories.zip(scores).select {|category,score| score > 0}.map {|category,score| category}
      suggested_categories
    end

end
