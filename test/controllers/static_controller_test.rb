require "test_helper"

class StaticControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get static_index_url
    assert_response :success
  end

  test "should get about" do
    get static_about_url
    assert_response :success
  end

  test "should get privacy" do
    get static_privacy_url
    assert_response :success
  end

  test "should get terms" do
    get static_terms_url
    assert_response :success
  end

  test "should get app" do
    get static_app_url
    assert_response :success
  end

  test "should get admin" do
    get static_admin_url
    assert_response :success
  end
end
