class AddEmailToPayments < ActiveRecord::Migration
  def self.up
    add_column :payments, :email, :string
  end

  def self.down
    remove_column :payments, :email
  end
end
