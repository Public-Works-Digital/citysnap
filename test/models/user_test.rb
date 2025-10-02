require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "user should be valid with email and password" do
    user = User.new(
      email: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    assert user.valid?
  end

  test "user should not be valid without email" do
    user = User.new(password: "password123")
    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "user should not be valid with duplicate email" do
    existing_user = users(:one)
    user = User.new(
      email: existing_user.email,
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "user should not be valid with invalid email format" do
    user = User.new(
      email: "invalid-email",
      password: "password123"
    )
    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "user should not be valid with short password" do
    user = User.new(
      email: "test@example.com",
      password: "short"
    )
    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 6 characters)"
  end

  test "user has many issues" do
    user = users(:one)
    assert_respond_to user, :issues
    assert_instance_of Issue, user.issues.first
  end

  test "destroying user should destroy associated issues" do
    user = users(:one)
    issue_count = user.issues.count

    assert_difference "Issue.count", -issue_count do
      user.destroy
    end
  end

  test "should default to citizen user type" do
    user = User.new(
      email: "newuser@example.com",
      password: "password123"
    )
    assert user.valid?
    assert_equal "citizen", user.user_type
  end

  test "should allow officer user type" do
    user = User.new(
      email: "newofficer@example.com",
      password: "password123",
      user_type: "officer"
    )
    assert user.valid?
    assert_equal "officer", user.user_type
  end

  test "should validate user_type presence" do
    user = User.new(
      email: "test@example.com",
      password: "password123"
    )
    user.user_type = nil
    assert_not user.valid?
    assert user.errors[:user_type].any?
  end

  test "should validate user_type inclusion" do
    user = User.new(
      email: "test@example.com",
      password: "password123"
    )
    assert_raises(ArgumentError) do
      user.user_type = "invalid_type"
    end
  end

  test "should scope citizens" do
    citizens = User.citizens
    assert_includes citizens, users(:one)
    assert_includes citizens, users(:two)
    assert_not_includes citizens, users(:officer)
  end

  test "should scope officers" do
    officers = User.officers
    assert_includes officers, users(:officer)
    assert_not_includes officers, users(:one)
    assert_not_includes officers, users(:two)
  end

  test "citizen_user_type? helper should work" do
    assert users(:one).citizen_user_type?
    assert_not users(:officer).citizen_user_type?
  end

  test "officer_user_type? helper should work" do
    assert users(:officer).officer_user_type?
    assert_not users(:one).officer_user_type?
  end
end
