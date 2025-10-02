require "test_helper"

class CommentsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @officer = users(:officer)
    @issue = issues(:one)
    sign_in @user
  end

  test "should create comment on open issue" do
    assert_difference("Comment.count") do
      post issue_comments_url(@issue), params: { comment: { body: "This is a test comment" } }
    end

    assert_redirected_to issue_url(@issue)
    assert_equal "Comment added successfully.", flash[:notice]
  end

  test "should not create comment without body" do
    assert_no_difference("Comment.count") do
      post issue_comments_url(@issue), params: { comment: { body: "" } }
    end

    assert_redirected_to issue_url(@issue)
    assert flash[:alert].present?
  end

  test "should not create comment on closed issue" do
    @issue.update!(status: "closed")

    assert_no_difference("Comment.count") do
      post issue_comments_url(@issue), params: { comment: { body: "Comment on closed issue" } }
    end

    assert_redirected_to issue_url(@issue)
    assert flash[:alert].present?
  end

  test "citizen should be able to delete their own comment" do
    comment = @issue.comments.create!(user: @user, body: "My comment")

    assert_difference("Comment.count", -1) do
      delete issue_comment_url(@issue, comment)
    end

    assert_redirected_to issue_url(@issue)
    assert_equal "Comment deleted successfully.", flash[:notice]
  end

  test "citizen should not be able to delete other user's comment" do
    other_user = users(:two)
    comment = @issue.comments.create!(user: other_user, body: "Other user's comment")

    assert_no_difference("Comment.count") do
      delete issue_comment_url(@issue, comment)
    end

    assert_redirected_to issue_url(@issue)
    assert_equal "You are not authorized to delete this comment.", flash[:alert]
  end

  test "officer should be able to delete any comment" do
    sign_out @user
    sign_in @officer

    comment = @issue.comments.create!(user: @user, body: "User's comment")

    assert_difference("Comment.count", -1) do
      delete issue_comment_url(@issue, comment)
    end

    assert_redirected_to issue_url(@issue)
    assert_equal "Comment deleted successfully.", flash[:notice]
  end

  test "should require authentication to create comment" do
    sign_out @user

    assert_no_difference("Comment.count") do
      post issue_comments_url(@issue), params: { comment: { body: "Anonymous comment" } }
    end

    assert_redirected_to new_user_session_url
  end

  test "officer comment should have officer badge" do
    sign_out @user
    sign_in @officer

    @issue.comments.create!(user: @officer, body: "Officer comment")

    get issue_url(@issue)
    assert_response :success
    assert_select "span.bg-blue-100", text: "Officer"
  end

  test "officer should be able to post comment and close issue" do
    sign_out @user
    sign_in @officer

    assert_equal "received", @issue.status

    assert_difference("Comment.count") do
      post issue_comments_url(@issue), params: { comment: { body: "Issue resolved" }, close_issue: "Post Comment and Close" }
    end

    @issue.reload
    assert_equal "closed", @issue.status
    assert_redirected_to issue_url(@issue)
    assert_equal "Comment added and issue closed successfully.", flash[:notice]
  end

  test "citizen should not be able to close issue when posting comment" do
    assert_equal "received", @issue.status

    assert_difference("Comment.count") do
      post issue_comments_url(@issue), params: { comment: { body: "My comment" }, close_issue: "Post Comment and Close" }
    end

    @issue.reload
    assert_equal "received", @issue.status
    assert_redirected_to issue_url(@issue)
    assert_equal "Comment added successfully.", flash[:notice]
  end
end
