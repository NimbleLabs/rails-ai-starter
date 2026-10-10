require "yaml"
require "json"

# This app's product settings: its name and its look. They live in
# config/app.yml, committed and deployed with the code, so every environment
# agrees, and bin/new-app hands the same choices to the mobile app at setup.
# Secrets and server settings stay in ENV.
#
# The look is a handful of choices (two fonts, two colors, a corner style);
# everything else is derived from them: hover and dark-mode shades, the text
# color that reads on the primary, a tinted panel color. The admin's Theme page
# (/admin/theme) previews changes and, in development, saves them here.
#
# Plain Ruby on purpose: bin/new-app loads this file without Rails.
class AppConfig
  PATH = "config/app.yml"

  class Invalid < StandardError; end

  HEX = /\A#\h{6}\z/
  EMAIL = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

  # The approved Google Fonts. Every one also ships as an Expo package
  # (@expo-google-fonts/<family-in-kebab-case>) for the mobile app, and the
  # weights listed are the ones from 400 to 800 that both offer. Display-only
  # faces are for headings and aren't offered for body text.
  FONTS = {
    "Outfit" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Inter" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "DM Sans" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Plus Jakarta Sans" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Manrope" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Poppins" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Nunito" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Work Sans" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Figtree" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Lexend" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Rubik" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Sora" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Montserrat" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Urbanist" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "IBM Plex Sans" => { category: "sans", weights: [ 400, 500, 600, 700 ] },
    "Exo 2" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ] },
    "Space Grotesk" => { category: "sans", weights: [ 400, 500, 600, 700 ] },
    "Lora" => { category: "serif", weights: [ 400, 500, 600, 700 ] },
    "Merriweather" => { category: "serif", weights: [ 400, 500, 600, 700, 800 ] },
    "Source Serif 4" => { category: "serif", weights: [ 400, 500, 600, 700, 800 ] },
    "Newsreader" => { category: "serif", weights: [ 400, 500, 600, 700, 800 ] },
    "Fraunces" => { category: "serif", weights: [ 400, 500, 600, 700, 800 ], display_only: true },
    "Playfair Display" => { category: "serif", weights: [ 400, 500, 600, 700, 800 ], display_only: true },
    "Libre Baskerville" => { category: "serif", weights: [ 400, 500, 600, 700 ], display_only: true },
    "DM Serif Display" => { category: "serif", weights: [ 400 ], display_only: true },
    "Instrument Serif" => { category: "serif", weights: [ 400 ], display_only: true },
    "Orbitron" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ], display_only: true },
    "Syne" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ], display_only: true },
    "Bricolage Grotesque" => { category: "sans", weights: [ 400, 500, 600, 700, 800 ], display_only: true },
    "Archivo Black" => { category: "sans", weights: [ 400 ], display_only: true }
  }.freeze

  FALLBACKS = { "sans" => "ui-sans-serif, system-ui, sans-serif", "serif" => "ui-serif, Georgia, serif" }.freeze

  # Card, button and form-field rounding for each corner style.
  CORNERS = {
    "sharp" => { card: "0.375rem", control: "0.375rem", field: "0.375rem" },
    "soft" => { card: "1rem", control: "1rem", field: "0.75rem" },
    "round" => { card: "1.5rem", control: "9999px", field: "1rem" }
  }.freeze

  # The neutrals the derived colors are measured against (application.css).
  CANVAS = "#fffaf0"
  WHITE = "#ffffff"
  BLACK = "#000000"
  INK = "#1c1410"
  DARK_SURFACE = "#1d1726"

  # WCAG's minimum for buttons, borders and large text. The primary must reach
  # it against white, which also guarantees white button text on it; in dark
  # mode it's lightened until it reaches it against the dark surface. (Small
  # text needs 4.5:1; the Theme page shows each ratio.)
  MINIMUM_CONTRAST = 3.0

  DEFAULTS = {
    "name" => "Starter",
    "short_name" => "ST",
    "tagline" => "Your app, ready to build on.",
    "support_email" => "",
    "theme" => {
      "display_font" => "Outfit",
      "body_font" => "Outfit",
      "primary" => "#7c3aed",
      "secondary" => "#6366f1",
      "corners" => "soft"
    }
  }.freeze

  class << self
    attr_writer :path

    def path
      @path || File.join(defined?(Rails) ? Rails.root.to_s : Dir.pwd, PATH)
    end

    # The committed config, reread whenever the file changes (the admin saves
    # it in development). Raises Invalid rather than rendering a broken look.
    def current
      mtime = File.exist?(path) ? File.mtime(path) : nil
      return @current if @current && @current_key == [ path, mtime ]

      config = mtime ? load(path) : new
      config.validate!
      @current_key = [ path, mtime ]
      @current = config
    end

    def load(file)
      new(YAML.safe_load_file(file) || {})
    end

    def expo_package(family)
      "@expo-google-fonts/#{family.downcase.tr(' ', '-')}"
    end
  end

  attr_reader :name, :short_name, :tagline, :support_email, :theme

  def initialize(attributes = {})
    attributes = stringify(attributes)
    defaults = DEFAULTS.merge("theme" => DEFAULTS["theme"].merge(stringify(attributes["theme"] || {})))
    values = defaults.merge(attributes.slice(*DEFAULTS.keys).reject { |key, _| key == "theme" })

    @name = values["name"].to_s.strip
    @short_name = values["short_name"].to_s.strip
    @tagline = values["tagline"].to_s.strip
    @support_email = values["support_email"].to_s.strip
    @theme = Theme.new(defaults["theme"])
  end

  def errors
    errors = []
    errors << "Name can't be blank." if name.empty?
    errors << "Name must be 60 characters or fewer." if name.length > 60
    errors << "Short name must be 1 to 3 characters." unless (1..3).cover?(short_name.length)
    errors << "Tagline must be 160 characters or fewer." if tagline.length > 160
    errors << "Support email isn't a valid address." unless support_email.empty? || support_email.match?(EMAIL)
    errors + theme.errors
  end

  def valid?
    errors.empty?
  end

  def validate!
    raise Invalid, "#{self.class.path}: #{errors.join(' ')}" unless valid?

    self
  end

  def to_h
    { "name" => name, "short_name" => short_name, "tagline" => tagline, "support_email" => support_email, "theme" => theme.to_h }
  end

  def ==(other)
    other.is_a?(AppConfig) && to_h == other.to_h
  end

  # The file as committed: every setting, explained. Strings go through JSON,
  # which is also valid YAML, so any name is quoted safely.
  def to_yaml
    <<~YAML
      # This app's product settings: its name and its look. Committed and deployed
      # with the code, and read by AppConfig. Secrets and server settings stay in ENV.
      #
      # The admin's Theme page (/admin/theme) previews changes and, in development,
      # saves them here. bin/new-app writes this file for a new project.

      # Shown in the nav, footer, sign-in pages, emails and the browser tab.
      name: #{name.to_json}
      # One to three letters for the brand mark.
      short_name: #{short_name.to_json}
      # One line about the product, used as the default page description.
      tagline: #{tagline.to_json}
      # Where people can reach a human. Shown in the footer when set.
      support_email: #{support_email.to_json}

      theme:
        # Headings: any font in AppConfig::FONTS.
        display_font: #{theme.display_font.to_json}
        # Body text: any font in AppConfig::FONTS that isn't display-only.
        body_font: #{theme.body_font.to_json}
        # Buttons, links and highlights. Must read on white (at least 3:1).
        primary: #{theme.primary.to_json}
        # Accents and gradients.
        secondary: #{theme.secondary.to_json}
        # sharp, soft or round.
        corners: #{theme.corners.to_json}
    YAML
  end

  def write(file = self.class.path)
    validate!
    File.write(file, to_yaml)
  end

  private

  def stringify(hash)
    hash.to_h.to_h { |key, value| [ key.to_s, value ] }
  end

  # The look: the choices, and the design tokens derived from them.
  class Theme
    attr_reader :display_font, :body_font, :primary, :secondary, :corners

    def initialize(values)
      @display_font = values["display_font"].to_s
      @body_font = values["body_font"].to_s
      @primary = values["primary"].to_s.strip.downcase
      @secondary = values["secondary"].to_s.strip.downcase
      @corners = values["corners"].to_s
    end

    def to_h
      { "display_font" => display_font, "body_font" => body_font, "primary" => primary, "secondary" => secondary, "corners" => corners }
    end

    def errors
      errors = []
      errors << "#{display_font.inspect} isn't on the approved font list." unless FONTS.key?(display_font)
      if !FONTS.key?(body_font)
        errors << "#{body_font.inspect} isn't on the approved font list."
      elsif FONTS[body_font][:display_only]
        errors << "#{body_font} is for headings only; pick another body font."
      end
      errors << "Corners must be one of #{CORNERS.keys.join(', ')}." unless CORNERS.key?(corners)
      errors << "Secondary must be a hex color like #6366f1." unless secondary.match?(HEX)
      if !primary.match?(HEX)
        errors << "Primary must be a hex color like #7c3aed."
      elsif contrast[:primary_on_white] < MINIMUM_CONTRAST
        errors << "Primary #{primary} is too light to read on white (#{contrast[:primary_on_white]}:1; " \
                  "it needs #{MINIMUM_CONTRAST}:1). Pick a darker shade."
      end
      errors
    end

    # The derived colors, light and dark. The CSS variables below and the
    # mobile app's branding.ts (MobileBranding) are both built from this.
    def palette
      dark = dark_primary
      {
        "light" => {
          "primary" => primary,
          "primary_hover" => Color.mix(primary, BLACK, 0.15),
          "on_primary" => on_primary,
          "secondary" => secondary,
          "surface_muted" => Color.mix(WHITE, primary, 0.06),
          "surface_selected" => Color.mix(WHITE, primary, 0.12)
        },
        "dark" => {
          "primary" => dark,
          "primary_hover" => Color.mix(dark, BLACK, 0.15),
          "on_primary" => Color.readable_on(dark),
          "secondary" => Color.mix(secondary, WHITE, 0.15),
          "surface_muted" => Color.mix(DARK_SURFACE, dark, 0.1),
          "surface_selected" => Color.mix(DARK_SURFACE, dark, 0.2)
        }
      }
    end

    # CSS custom properties for light and dark mode. application.css maps
    # them onto the Tailwind classes (bg-primary, rounded-card, font-display...).
    def css_variables
      radius = CORNERS.fetch(corners)
      colors = palette.transform_values do |shades|
        { "--theme-primary" => shades["primary"], "--theme-primary-hover" => shades["primary_hover"],
          "--theme-on-primary" => shades["on_primary"], "--theme-secondary" => shades["secondary"],
          "--theme-surface-muted" => shades["surface_muted"] }
      end
      {
        "light" => colors["light"].merge(
          "--theme-display-font" => font_stack(display_font),
          "--theme-body-font" => font_stack(body_font),
          "--theme-display-weight" => FONTS.fetch(display_font)[:weights].max.to_s,
          "--theme-border-radius" => radius[:card],
          "--theme-control-radius" => radius[:control],
          "--theme-field-radius" => radius[:field]
        ),
        "dark" => colors["dark"]
      }
    end

    # The <style> body every layout renders after application.css. Only
    # validated values reach it: hex colors, listed fonts, fixed radii.
    def css
      vars = css_variables
      ":root{#{declarations(vars['light'])}}.dark{#{declarations(vars['dark'])}}"
    end

    def google_fonts_url
      families = [ display_font, body_font ].uniq.map do |family|
        "family=#{family.tr(' ', '+')}:wght@#{FONTS.fetch(family)[:weights].join(';')}"
      end
      "https://fonts.googleapis.com/css2?#{families.join('&')}&display=swap"
    end

    # Text on primary fills: white, unless the primary is too light for it.
    def on_primary
      Color.readable_on(primary)
    end

    def contrast
      {
        primary_on_white: Color.contrast(primary, WHITE).round(1),
        on_primary: Color.contrast(on_primary, primary).round(1),
        dark_primary_on_surface: Color.contrast(dark_primary, DARK_SURFACE).round(1)
      }
    end

    # A step lighter for dark mode, and lighter still if it would otherwise
    # disappear into the dark surface (a navy primary, say).
    def dark_primary
      0.15.step(0.6, 0.05) do |amount|
        candidate = Color.mix(primary, WHITE, amount)
        return candidate if Color.contrast(candidate, DARK_SURFACE) >= MINIMUM_CONTRAST
      end
      Color.mix(primary, WHITE, 0.6)
    end

    private

    def font_stack(family)
      "'#{family}', #{FALLBACKS.fetch(FONTS.fetch(family)[:category])}"
    end

    def declarations(vars)
      vars.map { |property, value| "#{property}:#{value};" }.join
    end
  end

  # sRGB hex arithmetic: mixing and WCAG contrast.
  module Color
    module_function

    def rgb(hex)
      hex.delete("#").scan(/../).map { |pair| pair.to_i(16) }
    end

    def hex(rgb)
      "#" + rgb.map { |channel| channel.round.clamp(0, 255).to_s(16).rjust(2, "0") }.join
    end

    # `amount` of `other` mixed into `color`.
    def mix(color, other, amount)
      hex(rgb(color).zip(rgb(other)).map { |a, b| a + ((b - a) * amount) })
    end

    def luminance(color)
      r, g, b = rgb(color).map do |channel|
        value = channel / 255.0
        value <= 0.03928 ? value / 12.92 : ((value + 0.055) / 1.055)**2.4
      end
      (0.2126 * r) + (0.7152 * g) + (0.0722 * b)
    end

    def contrast(a, b)
      lighter, darker = [ luminance(a), luminance(b) ].sort.reverse
      (lighter + 0.05) / (darker + 0.05)
    end

    # White when it reads, otherwise whichever of white and ink reads better.
    def readable_on(color)
      return WHITE if contrast(WHITE, color) >= MINIMUM_CONTRAST

      contrast(WHITE, color) >= contrast(INK, color) ? WHITE : INK
    end
  end
end
