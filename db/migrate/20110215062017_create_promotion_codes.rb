class CreatePromotionCodes < ActiveRecord::Migration
  def self.up
    create_table :promotion_codes do |t|
       t.integer :price_point 
       t.string :code
       t.boolean :used , :default=>false				
       t.timestamps
    end
  end

  def self.down
    drop_table :promotion_codes
  end
end
