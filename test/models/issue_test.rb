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

  test "should default to received status" do
    issue = Issue.new(
      user: @user,
      comment: "Test issue"
    )
    assert issue.valid?
    assert_equal "received", issue.status
  end

  test "should validate status presence" do
    issue = Issue.new(
      user: @user,
      comment: "Test issue",
      status: nil
    )
    assert_not issue.valid?
    assert issue.errors[:status].any?
  end

  test "should validate status inclusion" do
    issue = Issue.new(
      user: @user,
      comment: "Test issue"
    )
    assert_raises(ArgumentError) do
      issue.status = "invalid_status"
    end
  end

  test "should allow valid status values" do
    issue = Issue.new(user: @user, comment: "Test")

    issue.status = "received"
    assert issue.valid?

    issue.status = "assigned"
    assert issue.valid?

    issue.status = "closed"
    assert issue.valid?
  end

  test "status_badge_color returns correct colors" do
    issue = Issue.new(user: @user, comment: "Test")

    issue.status = "received"
    assert_equal "bg-gray-100 text-gray-800", issue.status_badge_color

    issue.status = "assigned"
    assert_equal "bg-blue-100 text-blue-800", issue.status_badge_color

    issue.status = "closed"
    assert_equal "bg-green-100 text-green-800", issue.status_badge_color
  end

  test "should scope by status" do
    # Create test issues with different statuses
    received_issue = Issue.create!(user: @user, comment: "Received", status: "received")
    assigned_issue = Issue.create!(user: @user, comment: "Assigned", status: "assigned")
    closed_issue = Issue.create!(user: @user, comment: "Closed", status: "closed")

    assert_includes Issue.received, received_issue
    assert_includes Issue.assigned, assigned_issue
    assert_includes Issue.closed, closed_issue

    assert_not_includes Issue.received, assigned_issue
    assert_not_includes Issue.assigned, closed_issue
  end
end
