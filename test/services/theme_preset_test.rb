require "test_helper"

class ThemePresetTest < ActiveSupport::TestCase
  test "every bundled preset is a valid look" do
    presets = ThemePreset.all

    assert_equal "starter", presets.first["slug"], "the starter's own look comes first"
    presets.each do |preset|
      errors = AppConfig.new("theme" => preset["theme"]).theme.errors
      assert_empty errors, "#{preset['name']}: #{errors.join(' ')}"
    end
  end

  test "maps a Theme Builder export onto the config's settings" do
    preset = ThemePreset.from_export(
      "slug" => "neon", "name" => "Neon", "description" => "Bright.",
      "displayFont" => "Orbitron", "bodyFont" => "Exo 2", "borderRadius" => "none",
      "lightMode" => { "primary" => "#7c3aed", "secondary" => "#06b6d4" }, "darkMode" => { "primary" => "#a78bfa" }
    )

    assert_equal({ "display_font" => "Orbitron", "body_font" => "Exo 2", "primary" => "#7c3aed",
                   "secondary" => "#06b6d4", "corners" => "sharp" }, preset["theme"])
  end

  test "an unfamiliar radius falls back to soft corners" do
    assert_equal "soft", ThemePreset.from_export("borderRadius" => "huge")["theme"]["corners"]
  end
end
