require "test_helper"

class CommentTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @issue = issues(:one)
  end

  test "should be valid with all required attributes" do
    comment = Comment.new(
      user: @user,
      issue: @issue,
      body: "This is a test comment"
    )
    assert comment.valid?
  end

  test "should not be valid without body" do
    comment = Comment.new(user: @user, issue: @issue)
    assert_not comment.valid?
    assert comment.errors[:body].any?
  end

  test "should not be valid without user" do
    comment = Comment.new(issue: @issue, body: "Test")
    assert_not comment.valid?
    assert comment.errors[:user].any?
  end

  test "should not be valid without issue" do
    comment = Comment.new(user: @user, body: "Test")
    assert_not comment.valid?
    assert comment.errors[:issue].any?
  end

  test "should not be valid with body longer than 5000 characters" do
    comment = Comment.new(
      user: @user,
      issue: @issue,
      body: "a" * 5001
    )
    assert_not comment.valid?
    assert comment.errors[:body].any?
  end

  test "should not be valid on closed issue" do
    @issue.update!(status: "closed")
    comment = Comment.new(
      user: @user,
      issue: @issue,
      body: "Comment on closed issue"
    )
    assert_not comment.valid?
    assert_includes comment.errors[:base], "Cannot add comments to a closed issue"
  end

  test "should belong to user" do
    comment = Comment.create!(user: @user, issue: @issue, body: "Test")
    assert_equal @user, comment.user
  end

  test "should belong to issue" do
    comment = Comment.create!(user: @user, issue: @issue, body: "Test")
    assert_equal @issue, comment.issue
  end

  test "should be ordered by creation date" do
    comment1 = Comment.create!(user: @user, issue: @issue, body: "First", created_at: 2.days.ago)
    comment2 = Comment.create!(user: @user, issue: @issue, body: "Second", created_at: 1.day.ago)
    comment3 = Comment.create!(user: @user, issue: @issue, body: "Third", created_at: Time.current)

    ordered = Comment.ordered
    assert_equal comment1, ordered.first
    assert_equal comment3, ordered.last
  end
end
