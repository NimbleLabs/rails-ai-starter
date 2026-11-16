require "test_helper"
require_relative "../support/brand_artwork_rasterizing"

class SocialMetaTest < ActionDispatch::IntegrationTest
  include BrandArtworkRasterizing

  test "home page has Open Graph meta tags" do
    get root_url
    assert_response :success

    config = AppConfig.current
    assert_select 'meta[property="og:title"]' do |tags|
      assert_equal config.name, tags.first["content"]
    end
    assert_select 'meta[property="og:description"]'
    assert_select 'meta[property="og:image"]'
    assert_select 'meta[property="og:site_name"]' do |tags|
      assert_equal config.name, tags.first["content"]
    end
    assert_select 'meta[name="twitter:card"]' do |tags|
      assert_equal "summary_large_image", tags.first["content"]
    end
  end

  test "a page without its own picture shares the app's card, at an absolute URL" do
    get root_url

    assert_select 'meta[property="og:image"][content=?]', "http://www.example.com/og-image.png"
    assert_select 'meta[name="twitter:image"][content=?]', "http://www.example.com/og-image.png"
    assert_select 'meta[property="og:image:width"][content="1200"]'
    assert_select 'meta[property="og:image:height"][content="630"]'
  end

  # The tags and page shells point at plain files in public/, drawn at development time by
  # bin/rails brand:images. These check the committed ones are there and the size the tags say.
  test "the icons and share card the pages point at are committed" do
    public_dir = Rails.root.join("public")

    assert_equal [ 1200, 630 ], png_size(public_dir.join("og-image.png").binread)
    assert_equal [ BrandArtwork::ICON_SIZE, BrandArtwork::ICON_SIZE ], png_size(public_dir.join("favicon.png").binread)
    assert_equal "svg", Nokogiri::XML(public_dir.join("favicon.svg").read) { |options| options.strict }.root.name
  end

  test "an article with a featured image shares that image instead" do
    article = Article.create!(title: "Trail guide", description: "Where to walk", author: "Tester",
                              category: "Guides", published: true)
    article.featured_image.attach(io: StringIO.new("not really a png"), filename: "trail.png", content_type: "image/png")

    get article_url(article)
    assert_response :success

    assert_select 'meta[property="og:image"]' do |tags|
      assert_match %r{\Ahttp://www\.example\.com/rails/active_storage/blobs/.+/trail\.png\z}, tags.first["content"],
                   "link previews need an absolute URL, not a path"
    end
    assert_select 'meta[property="og:image:width"]', count: 0, message: "the article's own image isn't 1200x630"
  end

  test "home page has the SVG favicon" do
    get root_url
    assert_response :success
    assert_select 'link[rel="icon"][type="image/svg+xml"]'
    assert_select 'link[rel="icon"][type="image/png"]'
  end

  test "article show page has article-specific OG tags" do
    article = Article.create!(title: "Test Article", description: "A test description",
                              author: "Tester", category: "Testing", published: true)
    get article_url(article)
    assert_response :success

    assert_select 'meta[property="og:title"]' do |tags|
      assert_includes tags.first["content"], article.title
    end
    assert_select 'meta[property="og:description"]' do |tags|
      assert_equal article.description, tags.first["content"]
    end
  end
end
