class CreateProfiles < ActiveRecord::Migration
  def self.up
    create_table :profiles do |t|
      t.references :user

      t.string :name
      t.string :address
      t.string :phone
      t.string :email
      t.string :twitter
      t.string :facebook_url
      t.string :company_url

      t.timestamps
    end
  end

  def self.down
    drop_table :profiles
  end
end
