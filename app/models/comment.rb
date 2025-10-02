class Comment < ApplicationRecord
  belongs_to :issue
  belongs_to :user

  validates :body, presence: true, length: { minimum: 1, maximum: 5000 }
  validate :issue_not_closed

  scope :ordered, -> { order(created_at: :asc) }

  private

  def issue_not_closed
    if issue&.closed_status?
      errors.add(:base, "Cannot add comments to a closed issue")
    end
  end
end
