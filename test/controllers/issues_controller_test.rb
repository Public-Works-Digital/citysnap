require "test_helper"

class IssuesControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = users(:one)
    @issue = issues(:one)
    sign_in @user
  end

  test "should get index" do
    get issues_url
    assert_response :success
  end

  test "should redirect to login when not authenticated for index" do
    sign_out @user
    get issues_url
    assert_redirected_to new_user_session_url
  end

  test "should get new" do
    get new_issue_url
    assert_response :success
  end

  test "should create issue with location" do
    assert_difference("Issue.count") do
      post issues_url, params: { issue: {
        comment: "New pothole issue",
        latitude: 40.7128,
        longitude: -74.0060,
        street_address: "123 Test Street, New York"
      } }
    end

    assert_redirected_to issue_url(Issue.last)
    assert_equal "New pothole issue", Issue.last.comment
    assert_equal 40.7128, Issue.last.latitude
    assert_equal -74.0060, Issue.last.longitude
    assert_equal "123 Test Street, New York", Issue.last.street_address
  end

  test "should create issue without location" do
    assert_difference("Issue.count") do
      post issues_url, params: { issue: {
        comment: "General complaint"
      } }
    end

    assert_redirected_to issue_url(Issue.last)
    assert_equal "General complaint", Issue.last.comment
    assert_nil Issue.last.latitude
    assert_nil Issue.last.longitude
    assert_nil Issue.last.street_address
  end

  test "should not create issue with partial location" do
    assert_no_difference("Issue.count") do
      post issues_url, params: { issue: {
        comment: "Test issue",
        latitude: 40.7128
        # Missing longitude and street_address
      } }
    end

    assert_response :unprocessable_entity
  end

  test "should show issue" do
    get issue_url(@issue)
    assert_response :success
  end

  test "should not show other user's issue" do
    other_issue = issues(:two)
    get issue_url(other_issue)
    assert_response :not_found
  end

  test "should get edit for own issue" do
    get edit_issue_url(@issue)
    assert_response :success
  end

  test "should not get edit for other user's issue" do
    other_issue = issues(:two)
    get edit_issue_url(other_issue)
    assert_response :not_found
  end

  test "should update issue with location" do
    patch issue_url(@issue), params: { issue: {
      comment: "Updated comment",
      latitude: 41.8781,
      longitude: -87.6298,
      street_address: "789 Chicago Ave, Chicago"
    } }

    assert_redirected_to issue_url(@issue)
    @issue.reload
    assert_equal "Updated comment", @issue.comment
    assert_equal 41.8781, @issue.latitude
    assert_equal -87.6298, @issue.longitude
    assert_equal "789 Chicago Ave, Chicago", @issue.street_address
  end

  test "should update issue removing location" do
    patch issue_url(@issue), params: { issue: {
      comment: "Updated without location",
      latitude: "",
      longitude: "",
      street_address: ""
    } }

    assert_redirected_to issue_url(@issue)
    @issue.reload
    assert_equal "Updated without location", @issue.comment
    # All location fields should be cleared when empty strings are provided
    assert_nil @issue.latitude
    assert_nil @issue.longitude
    # Empty string is valid since all location fields are empty (treated as nil)
    assert @issue.valid?
  end

  test "should not update other user's issue" do
    other_issue = issues(:two)
    patch issue_url(other_issue), params: { issue: { comment: "Hacked!" } }
    assert_response :not_found
  end

  test "should destroy issue" do
    assert_difference("Issue.count", -1) do
      delete issue_url(@issue)
    end

    assert_redirected_to issues_url
  end

  test "should not destroy other user's issue" do
    other_issue = issues(:two)
    assert_no_difference("Issue.count") do
      delete issue_url(other_issue)
    end

    assert_response :not_found
  end

  test "should require authentication for most actions" do
    sign_out @user

    get new_issue_url
    assert_redirected_to new_user_session_url

    post issues_url, params: { issue: { comment: "Test" } }
    assert_redirected_to new_user_session_url

    get edit_issue_url(@issue)
    assert_redirected_to new_user_session_url

    patch issue_url(@issue), params: { issue: { comment: "Test" } }
    assert_redirected_to new_user_session_url

    delete issue_url(@issue)
    assert_redirected_to new_user_session_url
  end

  test "should allow public access to show action" do
    sign_out @user

    get issue_url(@issue)
    assert_response :success
  end

  test "should allow public access to public issues page" do
    sign_out @user

    get public_issues_url
    assert_response :success
  end
end
