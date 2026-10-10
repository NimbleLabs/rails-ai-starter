require "json"

# The Expo app's src/constants/branding.ts, generated from config/app.yml so
# the mobile app shares the web's name, colors, corners and fonts. Written by
# bin/sync-mobile-theme (which bin/new-app runs). Plain Ruby, like AppConfig,
# so it runs without Rails.
class MobileBranding
  PATH = "src/constants/branding.ts"

  # @expo-google-fonts export names: Inter_400Regular, Fraunces_800ExtraBold...
  WEIGHT_NAMES = { 400 => "400Regular", 500 => "500Medium", 600 => "600SemiBold", 700 => "700Bold", 800 => "800ExtraBold" }.freeze
  # React Native has one family per weight; text styles pick these. Every
  # approved body font has all four.
  BODY_WEIGHTS = { "regular" => 400, "medium" => 500, "semibold" => 600, "bold" => 700 }.freeze
  # AppConfig::CORNERS in points.
  RADII = {
    "sharp" => { "card" => 6, "control" => 6, "field" => 6 },
    "soft" => { "card" => 16, "control" => 16, "field" => 12 },
    "round" => { "card" => 24, "control" => 999, "field" => 16 }
  }.freeze

  def initialize(config)
    @config = config
    @theme = config.theme
  end

  def packages
    font_imports.keys
  end

  def body_families
    BODY_WEIGHTS.transform_values { |weight| family(@theme.body_font, weight) }
  end

  def display_family
    family(@theme.display_font, AppConfig::FONTS.fetch(@theme.display_font)[:weights].max)
  end

  # For gradients and the splash; 500 is the primary, as in the web's ramp.
  def ramp
    primary = @theme.primary
    color = AppConfig::Color
    {
      50 => color.mix(AppConfig::WHITE, primary, 0.06), 100 => color.mix(AppConfig::WHITE, primary, 0.12),
      200 => color.mix(AppConfig::WHITE, primary, 0.25), 500 => primary, 600 => color.mix(primary, AppConfig::BLACK, 0.15),
      700 => color.mix(primary, AppConfig::BLACK, 0.3), 900 => color.mix(primary, AppConfig::BLACK, 0.5)
    }
  end

  def to_ts
    palette = @theme.palette
    <<~TS
      // Generated from config/app.yml by the Rails app's bin/sync-mobile-theme.
      // Don't edit by hand: change the name or theme on the Rails admin's Theme
      // page (or in config/app.yml), then rerun bin/sync-mobile-theme.

      #{imports}

      /** App identity: the brand mark, the web tab bar label and the auth screens' copy. */
      export const Branding = {
        appName: #{string(@config.name)},
        markText: #{string(@config.short_name)},
        tagline: #{string(@config.tagline)},
      } as const;

      /** The brand colors and what's derived from them, light and dark (theme.ts maps them onto Colors). */
      export const BrandColors = {
        light: #{colors(palette['light'])},
        dark: #{colors(palette['dark'])},
      } as const;

      /** The primary's ramp, for gradients and the splash. 500 is the primary. */
      export const BrandRamp = {
      #{ramp.map { |step, hex| "  #{step}: #{string(hex)}," }.join("\n")}
      } as const;

      /** Corner radii for the "#{@theme.corners}" corner style. */
      export const BrandRadii = #{object(RADII.fetch(@theme.corners))} as const;

      /** Font files for useFonts() in the root layout. */
      export const BrandFontFiles = {
      #{font_imports.values.flatten.map { |name| "  #{name}," }.join("\n")}
      };

      /** #{@theme.body_font}, one family per weight: React Native doesn't synthesize weights. */
      export const BodyFont = #{object(body_families)} as const;

      /** Headings: #{@theme.display_font}. */
      export const DisplayFont = #{string(display_family)};
    TS
  end

  private

  def family(font, weight)
    "#{font.delete(' ')}_#{WEIGHT_NAMES.fetch(weight)}"
  end

  # { "@expo-google-fonts/inter" => ["Inter_400Regular", ...], ... }
  def font_imports
    names = body_families.values + [ display_family ]
    names.uniq.group_by { |name| AppConfig.expo_package(font_of(name)) }
  end

  def font_of(name)
    prefix = name.split("_").first
    AppConfig::FONTS.keys.find { |font| font.delete(" ") == prefix }
  end

  def imports
    font_imports.map do |package, names|
      "import {\n#{names.map { |name| "  #{name}," }.join("\n")}\n} from '#{package}';"
    end.join("\n")
  end

  def colors(shades)
    keys = { "primary" => "primary", "primary_hover" => "primaryHover", "on_primary" => "onPrimary", "secondary" => "secondary",
             "surface_muted" => "surfaceMuted", "surface_selected" => "surfaceSelected" }
    "{ #{keys.map { |from, to| "#{to}: #{string(shades.fetch(from))}" }.join(', ')} }"
  end

  def object(hash)
    "{ #{hash.map { |key, value| "#{key}: #{value.is_a?(String) ? string(value) : value}" }.join(', ')} }"
  end

  # A single-quoted TypeScript string. JSON handles the escaping; then swap the quotes.
  def string(value)
    "'#{value.to_s.to_json[1..-2].gsub('\\"', '"').gsub("'", "\\\\'")}'"
  end
end
