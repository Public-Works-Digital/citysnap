class Comment < ApplicationRecord
  belongs_to :issue
  belongs_to :user

  validates :body, presence: true, length: { minimum: 1, maximum: 5000 }
  validate :issue_not_closed

  scope :ordered, -> { order(created_at: :asc) }

  # Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    %w[id issue_id user_id body created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[issue user]
  end

  private

  def issue_not_closed
    if issue&.closed_status?
      errors.add(:base, "Cannot add comments to a closed issue")
    end
  end
end
