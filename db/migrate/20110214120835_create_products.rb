class CreateProducts < ActiveRecord::Migration
  def self.up
    create_table :products do |t|
      t.references :user

      t.string :style_num
      t.string :style_num_full
      t.string :style_description
      t.string :color_description
      t.float :first_cost
      t.float :ellc
      t.float :ticketed_retail
      t.float :ticketed_GM
      t.float :target_GM
      t.string :image_url

      t.timestamps
    end
  end

  def self.down
    drop_table :products
  end
end
