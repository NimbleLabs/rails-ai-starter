require "test_helper"

class SocialMetaTest < ActionDispatch::IntegrationTest
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
