class CreateUserIdentities < ActiveRecord::Migration[5.1]
  def change
    create_table :user_identities do |t|
      t.integer :user_id
      t.integer :email_id
      t.string :uid
      t.string :provider

      t.timestamps
    end
  end
end
