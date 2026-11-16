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

  test "the PNG is drawn once per config and redrawn when the config changes" do
    renders = 0
    counting = ->(svg) { renders += 1; "png of #{svg.hash}" }

    Rails.stub(:cache, ActiveSupport::Cache::MemoryStore.new) do
      BrandArtwork.stub(:rasterize, counting) do
        2.times { BrandArtwork.new(config).share_card_png }
        assert_equal 1, renders, "the same config should come from the cache"

        BrandArtwork.new(config(theme: { "primary" => "#0f766e" })).share_card_png
        assert_equal 2, renders, "a new theme needs a new card"
      end
    end
  end
end
