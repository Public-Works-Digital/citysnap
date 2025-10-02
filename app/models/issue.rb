class Issue < ApplicationRecord
  belongs_to :user
  has_one_attached :photo

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
