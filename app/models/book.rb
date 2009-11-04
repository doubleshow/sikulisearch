class Book < ActiveRecord::Base

  has_one :photo, :as => :photoable  

  include Photoable
  
  

  # Import many books from file
  #
  # input file:
  #
  # path/to/book1.jpg   this is a wonderful book
  # path/to/book2.jpg   this is a aweful book
  #
  def self.batch_import_from_input_file(input_file)
    File.open(input_file) do |f|
      f.readlines.each do |x|
        path, *title = x.split
        title = title.join(' ')        
        puts "importing #{path}"
        Book.create :title => title, :photo_file => path
      end
    end
  end

require 'amazon/aws'
require 'amazon/aws/search'
include Amazon::AWS
include Amazon::AWS::Search
ASSOCIATES_ID = "poq-20"
KEY_ID        = "12N9MPGBCMNSSTE9DVG2"

# lookup a book from amazon by its title
def self.lookup_book_from_amazon(title_text)

  # create a new AWS request 
  request  = Request.new( KEY_ID, ASSOCIATES_ID )
  
  # search the book by its title
  is = ItemSearch.new( 'Books', { 'Title' => title_text} )
  rg = ResponseGroup.new( 'Large' )
  
  # get only the first page result
  response = request.search( is, rg, 1) 
    
  # get only the first item on the first page
  book = response.item_sets.items[0]  

    puts "Title: #{book.title}"
    puts "Author: #{book.author}"
    puts "Price: $#{'%0.2f' % (book.list_price.amount.to_f/100)}"


#  response.item_sets.items.each do |book|
#  
#  if book.list_price  
#    puts "Title: #{book.title}"
#    puts "Author: #{book.author}"
#    puts "Price: $#{'%0.2f' % (book.list_price.amount.to_f/100)}"
#  end
#  end
##  puts "Rating: #{book.customer_reviews.average_rating}"  
#  puts "Publication date: #{book.publication_date}"
#    
   book
end 
  
  ###################################
    def ask(question)
      keywords = {}
      keywords[:price] = [
    'much',
    'cost',
    'price',
    'pay',
    'money',
    'sell',
    'sold']
      keywords[:rating] = [
    'rating',
    'good',
    'think',
    'like',
    'rated']    
      keywords[:author] = [
    'write',
    'wrote',
    'author',
    'written',
    'authored',
    'writer',
    'who']
      
      scores = {}
      keywords.keys.each do |topic|            
        scores[topic] = 0
        keywords[topic].each do |keyword|        
          if question =~ /#{keyword}/
            scores[topic] = scores[topic] + 1
          end
        end
      end
      
      # select the most likely topic
      winner = nil
      max_score = 0
      scores.keys.each do |topic|
        if scores[topic] > max_score
          max_score = scores[topic] 
          winner = topic  
        end
      end
      
      p winner
      
      
      if max_score == 0
        "Sorry, I don't know the answer to your question."
      else
      
      item  = Book.lookup_book_from_amazon(self.title)
                  
      answers = {}
      answers[:price] = "This book is sold at Amazon for <em>#{item.list_price.formatted_price}</em>."
      answers[:author] = "This book is written by <em>#{item.author}</em>."
      
      
      answers[:rating] = "This book has an average rating of <em>#{item.rating}</em.>"
            
      answers[winner] + "<br>The title of this book is <em>#{title}</em>."
      end
    end
  
    
end
