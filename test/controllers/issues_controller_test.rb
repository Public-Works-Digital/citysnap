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
    assert_equal "received", Issue.last.status
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
    assert_equal "received", Issue.last.status
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

  test "should show other user's issue (public access)" do
    other_issue = issues(:two)
    get issue_url(other_issue)
    assert_response :success
  end

  test "should get edit for own issue" do
    get edit_issue_url(@issue)
    assert_response :success
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


  test "should destroy issue" do
    assert_difference("Issue.count", -1) do
      delete issue_url(@issue)
    end

    assert_redirected_to issues_url
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

  # Officer tests
  test "officer should be able to edit any issue" do
    sign_out @user
    officer = users(:officer)
    sign_in officer

    other_issue = issues(:two)
    get edit_issue_url(other_issue)
    assert_response :success
  end

  test "officer should be able to update any issue status" do
    sign_out @user
    officer = users(:officer)
    sign_in officer

    other_issue = issues(:two)
    patch issue_url(other_issue), params: { issue: {
      status: "assigned"
    } }

    assert_redirected_to issue_url(other_issue)
    other_issue.reload
    assert_equal "assigned", other_issue.status
  end

  test "citizen should not be able to edit other user's issue" do
    other_issue = issues(:two)
    get edit_issue_url(other_issue)
    assert_redirected_to issues_path
    assert_equal "You are not authorized to edit this issue.", flash[:alert]
  end

  test "citizen should not be able to update other user's issue" do
    other_issue = issues(:two)
    patch issue_url(other_issue), params: { issue: {
      comment: "Hacked!"
    } }

    assert_redirected_to issues_path
    other_issue.reload
    assert_not_equal "Hacked!", other_issue.comment
  end

  test "citizen should not be able to change status of their own issue" do
    patch issue_url(@issue), params: { issue: {
      comment: "Updated comment",
      status: "closed"
    } }

    # Since status param is filtered out for citizens, update should succeed
    # but status should remain unchanged
    assert_redirected_to issue_url(@issue)
    @issue.reload
    assert_equal "Updated comment", @issue.comment
    # Status should remain unchanged because citizen cannot update it
    assert_equal "received", @issue.status
  end

  test "officer should see update button on issue show page" do
    sign_out @user
    officer = users(:officer)
    sign_in officer

    get issue_url(@issue)
    assert_response :success
    assert_select "a[href=?]", edit_issue_path(@issue), text: /Update Issue/
  end

  test "citizen should see edit button only on their own issues" do
    get issue_url(@issue)
    assert_response :success
    assert_select "a[href=?]", edit_issue_path(@issue), text: /Edit Issue/
  end

  test "citizen should not see edit button on other user's issues" do
    other_issue = issues(:two)
    get issue_url(other_issue)
    assert_response :success
    assert_select "a[href=?]", edit_issue_path(other_issue), count: 0
  end
end
