require "test_helper"

class BrandingControllerTest < ActionDispatch::IntegrationTest
  test "favicon returns an SVG with the app's initials and primary color" do
    get "/favicon.svg"
    assert_response :success
    assert_equal "image/svg+xml", response.media_type

    config = AppConfig.current
    assert_includes response.body, config.short_name
    assert_includes response.body, config.theme.primary
  end

  test "favicon is publicly cacheable" do
    get "/favicon.svg"
    assert_match(/public/, response.headers["Cache-Control"])
  end

  test "og image returns an SVG with the app name" do
    get "/og-image.svg"
    assert_response :success
    assert_equal "image/svg+xml", response.media_type
    assert_includes response.body, AppConfig.current.name
    assert_includes response.body, AppConfig.current.tagline
  end

  test "og image accepts custom title and description" do
    get "/og-image.svg", params: { title: "My Page", description: "A custom page" }
    assert_response :success
    assert_includes response.body, "My Page"
    assert_includes response.body, "A custom page"
  end

  test "og image truncates long titles" do
    long_title = "A" * 200
    get "/og-image.svg", params: { title: long_title }
    assert_response :success
    refute_includes response.body, long_title
  end

  test "og image is publicly cacheable" do
    get "/og-image.svg"
    assert_match(/public/, response.headers["Cache-Control"])
  end
end
