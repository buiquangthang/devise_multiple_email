class AddDefaultEmailToUsers < ActiveRecord::Migration[5.1]
  def change
    remove_column :users, :email
    add_column :users, :default_email_id, :integer
  end
end
