class AddEmployerToUsers < ActiveRecord::Migration
  def change
    add_column :users, :employer, :string
  end
end
