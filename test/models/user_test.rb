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
end
