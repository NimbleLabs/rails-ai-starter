require "test_helper"

class StaticControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should get about" do
    get about_url
    assert_response :success
  end

  test "should get privacy" do
    get privacy_url
    assert_response :success
  end

  test "should get terms" do
    get terms_url
    assert_response :success
  end

  test "app requires authentication" do
    get app_url
    assert_redirected_to new_user_session_url
  end

  test "admin requires authentication" do
    get admin_url
    assert_redirected_to new_user_session_url
  end

  test "signed-in user can load the app shell" do
    sign_in users(:two)
    get app_url
    assert_response :success
  end

  test "signed-in user can load the admin shell" do
    sign_in users(:one)
    get admin_url
    assert_response :success
  end
end
