class Issue < ApplicationRecord
  belongs_to :user
  belongs_to :category, optional: true  # Will be required after seeding
  has_one_attached :photo
  has_many :comments, dependent: :destroy

  # Status enum
  enum :status, { received: "received", assigned: "assigned", closed: "closed" }, default: "received", suffix: true

  # Status scopes
  scope :received, -> { where(status: "received") }
  scope :assigned, -> { where(status: "assigned") }
  scope :closed, -> { where(status: "closed") }

  # Geographic scope for filtering by map bounds
  scope :within_bounds, ->(south, west, north, east) {
    where("latitude >= ? AND latitude <= ? AND longitude >= ? AND longitude <= ?",
          south, north, west, east)
  }

  # Status validations
  validates :status, presence: true
  validates :status, inclusion: { in: %w[received assigned closed] }

  # Ransack configuration for ActiveAdmin
  def self.ransackable_attributes(auth_object = nil)
    %w[id user_id comment latitude longitude street_address status category_id created_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    %w[user category comments]
  end

  # Exclude ActiveStorage associations from Ransack
  def self.ransortable_attributes(auth_object = nil)
    ransackable_attributes(auth_object)
  end

  # Category validation - ensure it's a leaf node (level 3)
  validate :category_must_be_leaf_node, if: :category_id?

  def category_must_be_leaf_node
    return unless category

    if category.level != 3
      errors.add(:category, "must be a specific issue type (level 3)")
    end

    unless category.leaf?
      errors.add(:category, "must be a leaf category (cannot have subcategories)")
    end
  end

  # Location validations - only validate if present to allow existing issues without location
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }, allow_nil: true
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }, allow_nil: true
  validate :location_fields_presence

  # Helper methods for formatted display
  def formatted_coordinates
    "#{latitude.round(6)}, #{longitude.round(6)}"
  end

  def has_location?
    latitude.present? && longitude.present?
  end

  def status_badge_color
    case status
    when "received"
      "bg-gray-100 text-gray-800"
    when "assigned"
      "bg-blue-100 text-blue-800"
    when "closed"
      "bg-green-100 text-green-800"
    end
  end

  def category_full_name
    category&.full_name || "Uncategorized"
  end

  private

  def location_fields_presence
    # Ensure that if one location field is present, all must be present
    # Treat empty strings as nil for consistency
    lat = latitude.presence
    lng = longitude.presence
    addr = street_address.presence

    location_fields = [ lat, lng, addr ]
    if location_fields.any? && !location_fields.all?
      errors.add(:base, "All location fields (latitude, longitude, and address) must be provided together")
    end
  end
end
