# Draws the app's icons and link-preview card from config/app.yml. This is a development-time tool: run
# `bin/rails brand:images` on your machine and commit what it writes to public/, where the files are served as
# they are. Nothing draws images on the server, which doesn't have libvips (see CLAUDE.md).
#
# Colors come from the theme and AppConfig's neutrals, never literals, so a new theme redraws everything.
class BrandArtwork
  CARD_WIDTH = 1200
  CARD_HEIGHT = 630
  # The PNG icon: browsers without SVG favicons, and the home-screen icon on iPhones (which want 180x180).
  ICON_SIZE = 180
  # SVG text doesn't wrap, so the headline is split into lines by an estimate of how many characters fit.
  HEADLINE_LINES = 3
  HEADLINE_WIDTH = 1000

  def initialize(config = AppConfig.current)
    @config = config
    @theme = config.theme
  end

  # Writes favicon.svg, favicon.png and og-image.png into `dir` and returns their paths.
  def write(dir = Rails.root.join("public"))
    files = { "favicon.svg" => favicon_svg, "favicon.png" => icon_png, "og-image.png" => share_card_png }
    files.map do |name, content|
      File.join(dir, name).tap { |path| File.binwrite(path, content) }
    end
  end

  # The brand mark as an SVG drawn on a 32x32 grid: the app's initials on its primary color, in its corner
  # style. With `size`, it declares that many pixels, for converting to a PNG of that size.
  def favicon_svg(size: nil, rounded: true)
    dimensions = size ? %( width="#{size}" height="#{size}") : ""
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg"#{dimensions} viewBox="0 0 32 32">
        #{brand_mark(x: 0, y: 0, size: 32, rounded: rounded)}
      </svg>
    SVG
  end

  # The 1200x630 card shown beside a shared link: the brand mark and name, then the tagline as the headline.
  def share_card_svg
    headline = @config.tagline.presence || @config.name
    size = headline_font_size(headline)
    radius = { "sharp" => 0, "round" => 32 }.fetch(@theme.corners, 16)

    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="#{CARD_WIDTH}" height="#{CARD_HEIGHT}" viewBox="0 0 #{CARD_WIDTH} #{CARD_HEIGHT}">
        <rect width="#{CARD_WIDTH}" height="#{CARD_HEIGHT}" fill="#{AppConfig::CANVAS}"/>
        <rect x="40" y="40" width="1120" height="550" rx="#{radius}" fill="#{@theme.primary}" opacity="0.06"/>
        #{brand_mark(x: 80, y: 80, size: 80)}
        <text x="180" y="120" dominant-baseline="central" font-family="system-ui, sans-serif" font-weight="800"
              font-size="36" fill="#{AppConfig::INK}">#{escape(@config.name)}</text>
        <text x="80" y="260" font-family="system-ui, sans-serif" font-weight="700"
              font-size="#{size}" fill="#{AppConfig::INK}">#{headline_lines(headline, x: 80, font_size: size)}</text>
        <rect x="80" y="520" width="120" height="6" rx="3" fill="#{@theme.primary}"/>
      </svg>
    SVG
  end

  # The card as a PNG: Slack, iMessage, LinkedIn and X don't accept SVG for link previews.
  def share_card_png = self.class.rasterize(share_card_svg)

  # Square, because iPhones round a home-screen icon's corners themselves and fill transparent ones with black.
  def icon_png = self.class.rasterize(favicon_svg(size: ICON_SIZE, rounded: false))

  # SVG to PNG with libvips (`brew install vips` on a Mac). Tests run it in a fresh process: see
  # test/support/brand_artwork_rasterizing.rb for why.
  def self.rasterize(svg)
    require "vips"
    Vips::Image.new_from_buffer(svg, "").write_to_buffer(".png")
  end

  private

  def brand_mark(x:, y:, size:, rounded: true)
    radius = rounded ? (size * { "sharp" => 0.1, "round" => 0.35 }.fetch(@theme.corners, 0.2)).round : 0
    text_size = (size * { 1 => 0.6, 2 => 0.48 }.fetch(@config.short_name.length, 0.38)).round

    <<~SVG.strip
      <rect x="#{x}" y="#{y}" width="#{size}" height="#{size}" rx="#{radius}" fill="#{@theme.primary}"/>
      <text x="#{x + size / 2}" y="#{y + size / 2}" text-anchor="middle" dominant-baseline="central"
            font-family="system-ui, sans-serif" font-weight="800"
            font-size="#{text_size}" fill="#{@theme.on_primary}">#{escape(@config.short_name)}</text>
    SVG
  end

  def headline_font_size(text)
    return 56 if text.length <= 40
    return 48 if text.length <= 80
    40
  end

  # Words into at most HEADLINE_LINES lines, the last one ending in "…" if anything was cut. Each line is
  # escaped after it's cut, so a cut can never land inside an entity like &amp;.
  def headline_lines(text, x:, font_size:)
    per_line = (HEADLINE_WIDTH / (font_size * 0.55)).to_i
    lines = []
    text.split.each do |word|
      if lines.empty? || "#{lines.last} #{word}".length > per_line
        lines << word
      else
        lines[-1] = "#{lines.last} #{word}"
      end
    end

    if lines.size > HEADLINE_LINES
      lines = lines.first(HEADLINE_LINES)
      lines[-1] = "#{lines[-1].truncate(per_line - 1, omission: '')}…"
    end

    line_height = (font_size * 1.25).round
    lines.each_with_index.map do |line, index|
      %(<tspan x="#{x}" dy="#{index.zero? ? 0 : line_height}">#{escape(line)}</tspan>)
    end.join
  end

  def escape(text) = ERB::Util.html_escape(text)
end
