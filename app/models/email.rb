class Email < ApplicationRecord
  belongs_to :user
  validates :email, email: true, presence: true, uniqueness: true
end
