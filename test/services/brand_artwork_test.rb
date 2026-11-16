require "test_helper"
require_relative "../support/brand_artwork_rasterizing"

class BrandArtworkTest < ActiveSupport::TestCase
  include BrandArtworkRasterizing

  def config(**attributes)
    AppConfig.new({ "name" => "Trailhead", "short_name" => "TH", "tagline" => "Plan the hike, then take it." }.merge(attributes))
  end

  # Strict parsing raises on anything a browser or librsvg would choke on, like a bare & or <.
  def parse(svg) = Nokogiri::XML(svg) { |options| options.strict }

  test "the favicon is the app's initials on its primary color" do
    svg = BrandArtwork.new(config(theme: { "primary" => "#0f766e" })).favicon_svg

    doc = parse(svg)
    assert_equal "TH", doc.at_css("text").text
    assert_equal "#0f766e", doc.at_css("rect")["fill"]
  end

  test "the favicon follows the corner style" do
    sharp = parse(BrandArtwork.new(config(theme: { "corners" => "sharp" })).favicon_svg).at_css("rect")["rx"].to_i
    round = parse(BrandArtwork.new(config(theme: { "corners" => "round" })).favicon_svg).at_css("rect")["rx"].to_i

    assert_operator sharp, :<, round
  end

  test "the share card shows the name and the tagline, in theme colors" do
    svg = BrandArtwork.new(config(theme: { "primary" => "#0f766e" })).share_card_svg

    text = parse(svg).css("text").map(&:text).join(" ")
    assert_includes text, "Trailhead"
    assert_includes text, "Plan the hike, then take it."
    assert_includes svg, "#0f766e"
    assert_includes svg, AppConfig::CANVAS
  end

  test "the share card falls back to the name when there's no tagline" do
    headline = parse(BrandArtwork.new(config(tagline: "")).share_card_svg).css("text").last.text

    assert_equal "Trailhead", headline
  end

  test "markup in the name or tagline is escaped, not drawn" do
    svg = BrandArtwork.new(config(name: "Tom & Jerry's <Co>", tagline: "Fish & chips")).share_card_svg

    text = parse(svg).css("text").map(&:text).join(" ")
    assert_includes text, "Tom & Jerry's <Co>"
    assert_includes text, "Fish & chips"
  end

  test "a long tagline wraps to three lines and says it was cut" do
    tagline = ("Every trail in the park, " * 10).strip.truncate(160, omission: "")
    lines = parse(BrandArtwork.new(config(tagline: tagline)).share_card_svg).css("text").last.css("tspan")

    assert_equal BrandArtwork::HEADLINE_LINES, lines.size
    assert lines.last.text.end_with?("…")
  end

  test "cutting a long tagline never breaks an escaped character" do
    tagline = ("R&D " * 40).strip.truncate(160, omission: "")

    assert_nothing_raised { parse(BrandArtwork.new(config(tagline: tagline)).share_card_svg) }
  end

  test "the share card PNG is a 1200x630 picture" do
    png = with_fresh_process_rasterizer { BrandArtwork.new(config).share_card_png }

    assert_equal [ BrandArtwork::CARD_WIDTH, BrandArtwork::CARD_HEIGHT ], png_size(png)
  end

  test "the PNG icon is 180x180, the size iPhones want for home-screen icons" do
    png = with_fresh_process_rasterizer { BrandArtwork.new(config).icon_png }

    assert_equal [ BrandArtwork::ICON_SIZE, BrandArtwork::ICON_SIZE ], png_size(png)
  end

  test "the PNG icon is a full square, since iPhones round the corners themselves" do
    rendered = nil
    BrandArtwork.stub(:rasterize, ->(svg) { rendered = svg }) { BrandArtwork.new(config(theme: { "corners" => "round" })).icon_png }

    svg = parse(rendered)
    assert_equal "0", svg.at_css("rect")["rx"]
    assert_equal BrandArtwork::ICON_SIZE.to_s, svg.root["width"]
  end

  test "write puts the three files in the folder and returns their paths" do
    artwork = BrandArtwork.new(config)

    Dir.mktmpdir do |dir|
      paths = BrandArtwork.stub(:rasterize, ->(svg) { "png of #{svg.length} bytes" }) { artwork.write(dir) }

      assert_equal %w[favicon.svg favicon.png og-image.png].map { |name| File.join(dir, name) }, paths
      assert_equal artwork.favicon_svg, File.read(File.join(dir, "favicon.svg"))
      assert_equal "png of #{artwork.share_card_svg.length} bytes", File.binread(File.join(dir, "og-image.png"))
    end
  end

  test "write replaces files that are already there" do
    Dir.mktmpdir do |dir|
      File.write(File.join(dir, "favicon.svg"), "an old icon")

      BrandArtwork.stub(:rasterize, ->(_svg) { "png" }) { BrandArtwork.new(config).write(dir) }

      assert_includes File.read(File.join(dir, "favicon.svg")), "TH"
    end
  end
end
