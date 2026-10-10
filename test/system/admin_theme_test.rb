require "application_system_test_case"

class AdminThemeTest < ApplicationSystemTestCase
  setup do
    @dir = Pathname(Dir.mktmpdir("theme"))
    AppConfig.path = @dir.join("app.yml").to_s
    AppConfig.new.write
    login_as users(:one), scope: :user
  end

  teardown do
    AppConfig.path = nil
    FileUtils.rm_rf(@dir)
  end

  # The light sample's inline variables, which arrive from /theme/preview after a debounce.
  def assert_preview_primary(hex)
    assert_selector "[aria-hidden=true].bg-canvas[style*='--theme-primary: #{hex};']", visible: :all
  end

  test "a preset restyles the preview, and saving writes config/app.yml" do
    visit "/admin/theme"
    assert_selector "h1", text: "Theme"
    assert_preview_primary "#7c3aed"

    click_on "Nimble Labs"
    assert_selector "button[aria-pressed=true]", text: "Nimble Labs"
    assert_text "Headings set in Space Grotesk"
    assert_preview_primary "#0891b2"

    click_on "Save"
    assert_selector "h1", text: "Theme" # the page reloads with the saved theme
    assert_selector "style", text: /--theme-primary:#0891b2;/, visible: :all
    assert_equal "Space Grotesk", AppConfig.current.theme.display_font
  end

  test "a primary too light to read is explained and can't be saved" do
    visit "/admin/theme"
    find("input[aria-label='Primary hex']").fill_in(with: "#facc15")

    assert_text "too light to read on white"
    assert_button "Save", disabled: true
  end
end
