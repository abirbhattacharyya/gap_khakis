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

ActiveRecord::Schema.define(:version => 20110216112051) do

  create_table "offers", :force => true do |t|
    t.string   "ip"
    t.string   "response"
    t.integer  "product_id"
    t.float    "price"
    t.integer  "counter"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", :force => true do |t|
    t.integer  "offer_id"
    t.integer  "promotion_code_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "products", :force => true do |t|
    t.integer  "user_id"
    t.string   "style_num"
    t.string   "style_num_full"
    t.string   "style_description"
    t.string   "color_description"
    t.float    "first_cost"
    t.float    "ellc"
    t.float    "ticketed_retail"
    t.float    "ticketed_GM"
    t.float    "target_GM"
    t.string   "image_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "profiles", :force => true do |t|
    t.integer  "user_id"
    t.string   "name"
    t.string   "address"
    t.string   "phone"
    t.string   "email"
    t.string   "twitter"
    t.string   "facebook_url"
    t.string   "company_url"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "promotion_codes", :force => true do |t|
    t.integer  "price_point"
    t.string   "code"
    t.boolean  "used",        :default => false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", :force => true do |t|
    t.string   "email"
    t.string   "password"
    t.string   "remember_token"
    t.datetime "remember_token_expires_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "is_blocked",                :default => false
  end

end
