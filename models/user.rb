require 'active_record'

class User < ActiveRecord::Base
  has_many :tasks, dependent: :destroy

  validates :uid, presence: true, uniqueness: true
end
