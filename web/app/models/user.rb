class User < ActiveRecord::Base
  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :omniauthable, :database_authenticatable, :registerable, :recoverable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :remember_me, :fb_user_id, :name, :image, :location, :employer


  def self.find_or_create_from_auth_hash(auth_hash)
    user_data = auth_hash.extra.raw_info
    if user = User.where(:fb_user_id => user_data.id).first
      user
    else # Create a user with a stub password.
      User.create!(:fb_user_id => user_data.id, :name => user_data.name, :email => user_data.email, :image => auth_hash.info.image, :location => auth_hash.info.location, :employer => user_data.work.first.employer.name)
    end
  end
end
