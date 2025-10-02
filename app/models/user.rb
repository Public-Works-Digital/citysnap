class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :recoverable, :rememberable, :validatable
  has_many :issues, dependent: :destroy
  has_many :comments, dependent: :destroy

  # User type enum
  enum :user_type, { citizen: "citizen", officer: "officer", admin: "admin" }, default: "citizen", suffix: true

  # Scopes
  scope :citizens, -> { where(user_type: "citizen") }
  scope :officers, -> { where(user_type: "officer") }
  scope :admins, -> { where(user_type: "admin") }

  # Validations
  validates :user_type, presence: true
  validates :user_type, inclusion: { in: %w[citizen officer admin] }

  # Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    %w[id email user_type created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[issues comments]
  end

  # Display name for ActiveAdmin dropdowns
  def display_name
    "#{email} (#{user_type})"
  end
end
