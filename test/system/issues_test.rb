require "application_system_test_case"

class IssuesTest < ApplicationSystemTestCase
  include Devise::Test::IntegrationHelpers

  setup do
    @issue = issues(:one)
    @user = users(:one)
    sign_in @user
  end

  test "visiting the index" do
    visit issues_url
    assert_selector "h1", text: "My Reported Issues"
  end

  test "should create issue" do
    visit new_issue_url

    # Get the category ID for "Parking in crosswalk" from fixtures
    category = categories(:vehicles_parking_crosswalk)

    # Note: The form uses JavaScript for cascading category dropdowns and an interactive map.
    # To keep tests fast and reliable, we set the hidden form fields directly via JavaScript
    # rather than simulating all the user interactions with dropdowns and map clicks.
    page.execute_script("document.querySelector('[data-category-selector-target=\"categoryId\"]').value = #{category.id}")
    page.execute_script("document.querySelector('[data-map-target=\"latitude\"]').value = 37.7749")
    page.execute_script("document.querySelector('[data-map-target=\"longitude\"]').value = -122.4194")
    page.execute_script("document.querySelector('[data-map-target=\"address\"]').value = '123 Test St, San Francisco, CA'")

    fill_in "Description", with: "Test issue description"

    # Scroll to bottom to ensure button is in view
    page.execute_script("window.scrollTo(0, document.body.scrollHeight)")

    # Click the submit button
    find("input[value='Report Issue']").click

    assert_text "Issue was successfully created"
  end

  test "should update Issue" do
    visit issue_url(@issue)
    click_on "Edit Issue"

    fill_in "Description", with: "Updated issue description"
    click_on "Update Issue"

    assert_text "Issue was successfully updated"
  end

  test "should destroy Issue" do
    visit issue_url(@issue)
    accept_confirm { click_on "Delete Issue" }

    assert_text "Issue was successfully destroyed"
  end
end
