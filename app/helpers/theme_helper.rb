module ThemeHelper
  DEFAULT_THEME_SLUG = "starter".freeze

  def available_themes
    @available_themes ||= Dir.glob(Rails.root.join("lib/themes/*-theme.json")).map do |path|
      JSON.parse(File.read(path))["theme"]
    end.sort_by { |t| [ t["slug"] == DEFAULT_THEME_SLUG ? 0 : 1, t["name"] ] }
  end

  def themes_json
    available_themes.to_json
  end

  def default_theme_slug
    available_themes.find { |t| t["slug"] == DEFAULT_THEME_SLUG }&.dig("slug") ||
      available_themes.first&.dig("slug") ||
      DEFAULT_THEME_SLUG
  end
end
