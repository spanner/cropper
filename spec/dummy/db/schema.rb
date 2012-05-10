# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20120510104910) do

  create_table "things", :force => true do |t|
    t.string   "friend_file_name"
    t.string   "friend_content_type"
    t.integer  "friend_file_size"
    t.datetime "friend_updated_at"
    t.integer  "friend_upload_id"
    t.integer  "friend_scale_width"
    t.integer  "friend_scale_height"
    t.integer  "friend_offset_left"
    t.integer  "friend_offset_top"
    t.integer  "friend_version"
    t.string   "pet_file_name"
    t.string   "pet_content_type"
    t.integer  "pet_file_size"
    t.datetime "pet_updated_at"
    t.integer  "pet_upload_id"
    t.integer  "pet_scale_width"
    t.integer  "pet_scale_height"
    t.integer  "pet_offset_left"
    t.integer  "pet_offset_top"
    t.integer  "pet_version"
  end

  create_table "uploads", :force => true do |t|
    t.string   "file_file_name"
    t.string   "file_content_type"
    t.integer  "file_file_size"
    t.datetime "file_updated_at"
    t.string   "original_extension"
    t.integer  "original_width"
    t.integer  "original_height"
    t.datetime "created_at",         :null => false
    t.datetime "updated_at",         :null => false
  end

end
