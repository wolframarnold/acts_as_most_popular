ActiveRecord::Schema.define do
  create_table "items", :force => true do |t|
    t.string "title"
  end

  create_table "viewings", :force => true do |t|
    t.integer "item_id"
  end
end
