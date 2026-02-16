module ThemeHelper
  def available_themes
    @available_themes ||= Dir.glob(Rails.root.join("lib/themes/*-theme.json")).map do |path|
      JSON.parse(File.read(path))["theme"]
    end.sort_by { |t| t["name"] }
  end

  def themes_json
    available_themes.to_json
  end

  def default_theme_slug
    available_themes.first&.dig("slug") || "nimble-labs"
  end
end
