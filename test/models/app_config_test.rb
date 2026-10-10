require "test_helper"

class AppConfigTest < ActiveSupport::TestCase
  setup { @dir = Pathname(Dir.mktmpdir("app-config")) }

  teardown do
    AppConfig.path = nil
    FileUtils.rm_rf(@dir)
  end

  def config(theme = {}, **attributes)
    AppConfig.new(attributes.merge(theme: theme))
  end

  test "the committed config/app.yml is valid" do
    assert AppConfig.load(Rails.root.join(AppConfig::PATH)).valid?, AppConfig.load(Rails.root.join(AppConfig::PATH)).errors.join(" ")
  end

  test "defaults to the starter's look when a setting is missing" do
    partial = AppConfig.new("name" => "Acme", "theme" => { "primary" => "#0F766E" })

    assert_equal "Acme", partial.name
    assert_equal "ST", partial.short_name
    assert_equal "#0f766e", partial.theme.primary, "hex is normalised to lower case"
    assert_equal "Outfit", partial.theme.display_font
    assert partial.valid?
  end

  test "writes a file that reads back the same, comments and all" do
    original = config({ display_font: "Fraunces", body_font: "Source Serif 4", corners: "round" },
                      name: %(Bob's "Recipes": #1), short_name: "BR", support_email: "help@bob.test")
    path = @dir.join("app.yml")
    original.write(path)

    assert_equal original, AppConfig.load(path)
    assert_match "# Headings: any font in AppConfig::FONTS.", path.read
  end

  test "rejects fonts off the list, a display-only body font, unknown corners and bad hex" do
    errors = config({ display_font: "Comic Sans", body_font: "Orbitron", corners: "pill", secondary: "blue" }).errors

    assert_includes errors, %("Comic Sans" isn't on the approved font list.)
    assert_includes errors, "Orbitron is for headings only; pick another body font."
    assert_includes errors, "Corners must be one of sharp, soft, round."
    assert_includes errors, "Secondary must be a hex color like #6366f1."
  end

  test "rejects a primary too light to read on white, saying how far off it is" do
    errors = config({ primary: "#facc15" }).errors

    assert_equal [ "Primary #facc15 is too light to read on white (1.5:1; it needs 3.0:1). Pick a darker shade." ], errors
    assert config({ primary: "#0891b2" }).valid?, "3.7:1 is enough for buttons and large text"
  end

  test "checks the name, initials and support email" do
    errors = config(name: "", short_name: "ABCD", support_email: "nope").errors

    assert_includes errors, "Name can't be blank."
    assert_includes errors, "Short name must be 1 to 3 characters."
    assert_includes errors, "Support email isn't a valid address."
    assert config(support_email: "").valid?, "support email is optional"
  end

  test "derives hover, text-on-primary and dark-mode shades from the primary" do
    light, dark = config({ primary: "#7c3aed" }).theme.css_variables.values_at("light", "dark")

    assert_equal "#7c3aed", light["--theme-primary"]
    assert_equal "#6931c9", light["--theme-primary-hover"], "15% darker"
    assert_equal "#ffffff", light["--theme-on-primary"]
    assert_equal "#9058f0", dark["--theme-primary"], "a step lighter on the dark surface"
  end

  test "lightens a dark primary further in dark mode so it doesn't vanish" do
    theme = config({ primary: "#1e3a8a" }).theme

    assert_operator AppConfig::Color.contrast(theme.dark_primary, AppConfig::DARK_SURFACE), :>=, AppConfig::MINIMUM_CONTRAST
    assert_operator AppConfig::Color.contrast(AppConfig::Color.mix("#1e3a8a", "#ffffff", 0.15), AppConfig::DARK_SURFACE),
                    :<, AppConfig::MINIMUM_CONTRAST, "the usual 15% step wouldn't have been enough"
  end

  test "uses dark text on a primary too light for white" do
    assert_equal AppConfig::INK, AppConfig::Color.readable_on("#fbbf24")
    assert_equal AppConfig::WHITE, AppConfig::Color.readable_on("#7c3aed")
  end

  test "maps corners and fonts onto CSS, falling back to the right generic family" do
    vars = config({ display_font: "DM Serif Display", body_font: "Inter", corners: "round" }).theme.css_variables["light"]

    assert_equal "'DM Serif Display', ui-serif, Georgia, serif", vars["--theme-display-font"]
    assert_equal "'Inter', ui-sans-serif, system-ui, sans-serif", vars["--theme-body-font"]
    assert_equal "400", vars["--theme-display-weight"], "a single-weight face isn't asked for 800"
    assert_equal "9999px", vars["--theme-control-radius"]
  end

  test "asks Google Fonts for each family once, with the weights it has" do
    assert_equal "https://fonts.googleapis.com/css2?family=Outfit:wght@400;500;600;700;800&display=swap",
                 config({ display_font: "Outfit", body_font: "Outfit" }).theme.google_fonts_url
    assert_equal "https://fonts.googleapis.com/css2?family=Lora:wght@400;500;600;700&family=Source+Serif+4:wght@400;500;600;700;800&display=swap",
                 config({ display_font: "Lora", body_font: "Source Serif 4" }).theme.google_fonts_url
  end

  test "renders one :root and one .dark rule" do
    css = config.theme.css

    assert_match(/\A:root\{--theme-primary:#7c3aed;.*\}\.dark\{--theme-primary:#9058f0;.*\}\z/, css)
  end

  test "names each font's Expo package for the mobile app" do
    assert_equal "@expo-google-fonts/source-serif-4", AppConfig.expo_package("Source Serif 4")
    assert_equal "@expo-google-fonts/dm-sans", AppConfig.expo_package("DM Sans")
  end

  test "current rereads the file when it changes, and refuses an invalid one" do
    AppConfig.path = @dir.join("app.yml").to_s
    config(name: "First").write(AppConfig.path)
    assert_equal "First", AppConfig.current.name

    config(name: "Second").write(AppConfig.path)
    File.utime(Time.now + 5, Time.now + 5, AppConfig.path)
    assert_equal "Second", AppConfig.current.name

    File.write(AppConfig.path, { "theme" => { "primary" => "#ffff00" } }.to_yaml)
    File.utime(Time.now + 10, Time.now + 10, AppConfig.path)
    assert_raises(AppConfig::Invalid) { AppConfig.current }
  end

  test "without a file it's the starter's defaults" do
    AppConfig.path = @dir.join("missing.yml").to_s

    assert_equal AppConfig.new, AppConfig.current
  end
end
