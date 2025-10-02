class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  has_many :issues, dependent: :destroy

  # User type enum
  enum :user_type, { citizen: "citizen", officer: "officer" }, default: "citizen", suffix: true

  # Scopes
  scope :citizens, -> { where(user_type: "citizen") }
  scope :officers, -> { where(user_type: "officer") }

  # Validations
  validates :user_type, presence: true
  validates :user_type, inclusion: { in: %w[citizen officer] }
end
