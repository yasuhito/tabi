class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :remember_me, :fb_user_id, :name


  def self.find_or_create_from_auth_hash(auth_hash)
    user_data = auth_hash.extra.raw_info
    if user = User.where(:fb_user_id => user_data.id).first
      user
    else # Create a user with a stub password.
      User.create!(:fb_user_id => user_data.id, :name => user_data.name, :email => user_data.email)
    end
  end
end
