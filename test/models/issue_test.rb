require "test_helper"

class IssueTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
  end

  test "should be valid with all location fields" do
    issue = Issue.new(
      user: @user,
      comment: "Test issue",
      latitude: 40.7128,
      longitude: -74.0060,
      street_address: "123 Test St, New York"
    )
    assert issue.valid?
  end

  test "should be valid without any location fields" do
    issue = Issue.new(
      user: @user,
      comment: "Test issue without location"
    )
    assert issue.valid?
  end

  test "should not be valid with only latitude" do
    issue = Issue.new(
      user: @user,
      comment: "Test issue",
      latitude: 40.7128
    )
    assert_not issue.valid?
    assert_includes issue.errors[:base], "All location fields (latitude, longitude, and address) must be provided together"
  end

  test "should not be valid with only longitude" do
    issue = Issue.new(
      user: @user,
      comment: "Test issue",
      longitude: -74.0060
    )
    assert_not issue.valid?
    assert_includes issue.errors[:base], "All location fields (latitude, longitude, and address) must be provided together"
  end

  test "should not be valid with only street address" do
    issue = Issue.new(
      user: @user,
      comment: "Test issue",
      street_address: "123 Test St"
    )
    assert_not issue.valid?
    assert_includes issue.errors[:base], "All location fields (latitude, longitude, and address) must be provided together"
  end

  test "should not be valid with latitude out of range" do
    issue = Issue.new(
      user: @user,
      comment: "Test issue",
      latitude: 91,
      longitude: -74.0060,
      street_address: "123 Test St"
    )
    assert_not issue.valid?
    assert issue.errors[:latitude].any?
  end

  test "should not be valid with longitude out of range" do
    issue = Issue.new(
      user: @user,
      comment: "Test issue",
      latitude: 40.7128,
      longitude: 181,
      street_address: "123 Test St"
    )
    assert_not issue.valid?
    assert issue.errors[:longitude].any?
  end

  test "should belong to user" do
    issue = issues(:one)
    assert_instance_of User, issue.user
  end

  test "formatted_coordinates returns correct format" do
    issue = issues(:one)
    assert_equal "40.7128, -74.006", issue.formatted_coordinates
  end

  test "has_location? returns true when location present" do
    issue = issues(:one)
    assert issue.has_location?
  end

  test "has_location? returns false when location not present" do
    issue = issues(:three)
    assert_not issue.has_location?
  end
end
