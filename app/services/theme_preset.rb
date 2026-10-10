# Ready-made looks from lib/themes/*-theme.json (exported by the Nimble Labs
# Theme Builder), offered on the admin Theme page as starting points. Each maps
# onto config/app.yml's theme settings; the rest of a preset (its backgrounds,
# shadows) isn't part of the configurable look, so it's ignored here.
class ThemePreset
  DIRECTORY = "lib/themes"
  DEFAULT_SLUG = "starter".freeze
  # The Theme Builder's radius names onto AppConfig::CORNERS.
  CORNERS = { "none" => "sharp", "sm" => "sharp", "md" => "sharp", "lg" => "soft", "xl" => "soft",
              "2xl" => "round", "3xl" => "round", "full" => "round" }.freeze

  # The starter's own look first, then by name.
  def self.all(root: Rails.root)
    Dir.glob(File.join(root, DIRECTORY, "*-theme.json")).map { |path| from_export(JSON.parse(File.read(path))["theme"]) }
       .sort_by { |preset| [ preset["slug"] == DEFAULT_SLUG ? 0 : 1, preset["name"] ] }
  end

  def self.from_export(theme)
    {
      "slug" => theme["slug"],
      "name" => theme["name"],
      "description" => theme["description"],
      "theme" => {
        "display_font" => theme["displayFont"],
        "body_font" => theme["bodyFont"],
        "primary" => theme.dig("lightMode", "primary"),
        "secondary" => theme.dig("lightMode", "secondary"),
        "corners" => CORNERS.fetch(theme["borderRadius"], "soft")
      }
    }
  end
end
