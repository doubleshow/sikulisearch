# This file is auto-generated from the current state of the database. Instead of editing this file, 
# please use the migrations feature of Active Record to incrementally modify your database, and
# then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your database schema. If you need
# to create the application database on another system, you should be using db:schema:load, not running
# all the migrations from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 18) do

  create_table "books", :force => true do |t|
    t.text     "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "groceries", :force => true do |t|
    t.text     "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "movies", :force => true do |t|
    t.text     "title"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pdf_books", :force => true do |t|
    t.string   "title"
    t.string   "isbn"
    t.integer  "pages"
    t.string   "source_file"
    t.integer  "cover_photo_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "pdf_figures", :force => true do |t|
    t.integer  "pdf_page_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "ocr"
  end

  create_table "pdf_pages", :force => true do |t|
    t.integer  "number"
    t.integer  "pdf_book_id"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "photos", :force => true do |t|
    t.integer  "photoable_id"
    t.string   "photoable_type"
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.integer  "width"
    t.integer  "height"
  end

  create_table "queries", :force => true do |t|
    t.string   "source"
    t.string   "result_ids"
    t.string   "target_ids"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "questions", :force => true do |t|
    t.integer  "query_id"
    t.text     "text"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "screenshots", :force => true do |t|
    t.text     "keywords"
    t.string   "application"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "search_result"
    t.string   "labels"
    t.string   "knns"
  end

  create_table "video_frames", :force => true do |t|
    t.integer "video_id"
    t.integer "number"
    t.float   "start_second"
    t.float   "end_second"
  end

  create_table "video_segments", :force => true do |t|
    t.integer "start_frame_id"
    t.integer "end_frame_id"
  end

  create_table "videos", :force => true do |t|
    t.string "title"
  end

  create_table "web_figures", :force => true do |t|
    t.string   "pageurl"
    t.string   "imageurl"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

end
