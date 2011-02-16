class CreatePayments < ActiveRecord::Migration
  def self.up
    create_table :payments do |t|
      t.integer :offer_id
      t.integer :promotion_code_id

      t.timestamps
    end
  end

  def self.down
    drop_table :payments
  end
end
