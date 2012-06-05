class AddFbColumnsToUsers < ActiveRecord::Migration
  def change
    add_column :users, :name, :string
    add_column :users, :fb_user_id, :integer
  end
end
