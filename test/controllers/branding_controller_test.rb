require "test_helper"
require_relative "../support/brand_artwork_rasterizing"

class BrandingControllerTest < ActionDispatch::IntegrationTest
  include BrandArtworkRasterizing

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

  # Stands in for libvips where a test only cares what was drawn: the "PNG" is the SVG it was drawn from.
  def with_svg_passthrough(&block) = BrandArtwork.stub(:rasterize, ->(svg) { svg }, &block)

  test "the share image is a 1200x630 PNG, since link previews don't accept SVG" do
    with_fresh_process_rasterizer { get "/og-image.png" }

    assert_response :success
    assert_equal "image/png", response.media_type
    assert_equal [ 1200, 630 ], png_size(response.body)
  end

  test "the share image is publicly cacheable" do
    with_svg_passthrough { get "/og-image.png" }

    assert_match(/public/, response.headers["Cache-Control"])
  end

  test "the share image can't be made to say something else" do
    with_svg_passthrough do
      get "/og-image.png", params: { title: "Your account is locked", description: "Sign in here" }
    end

    assert_includes response.body, AppConfig.current.name
    assert_not_includes response.body, "Your account is locked", "query parameters must not change the branded image"
    assert_not_includes response.body, "Sign in here"
  end
end
