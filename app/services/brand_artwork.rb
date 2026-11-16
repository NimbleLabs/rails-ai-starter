# The app's favicon and link-preview card, drawn from config/app.yml so every app made from the starter has its
# own from the first deploy, without anyone opening an image editor. BrandingController serves them.
#
# Colors come from the theme and AppConfig's neutrals, never literals, so a new theme redraws both.
class BrandArtwork
  CARD_WIDTH = 1200
  CARD_HEIGHT = 630
  # SVG text doesn't wrap, so the headline is split into lines by an estimate of how many characters fit.
  HEADLINE_LINES = 3
  HEADLINE_WIDTH = 1000

  def initialize(config = AppConfig.current)
    @config = config
    @theme = config.theme
  end

  # The brand mark as a 32x32 SVG: the app's initials on its primary color, in its corner style.
  def favicon_svg
    <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
        #{brand_mark(x: 0, y: 0, size: 32)}
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

  # The card as a PNG. Slack, iMessage, LinkedIn and X don't accept SVG for link previews, so libvips converts
  # it. It only changes when config/app.yml does, so it's cached under a digest of the config.
  def share_card_png
    Rails.cache.fetch([ "brand-artwork/share-card", Digest::SHA256.hexdigest(@config.to_h.to_json) ]) do
      self.class.rasterize(share_card_svg)
    end
  end

  # SVG to PNG with libvips. It's loaded here rather than at boot, so a server without it loses this one image,
  # not the app. Tests run it in a fresh process: see test/support/brand_artwork_rasterizing.rb for why.
  def self.rasterize(svg)
    require "vips"
    Vips::Image.new_from_buffer(svg, "").write_to_buffer(".png")
  end

  private

  def brand_mark(x:, y:, size:)
    radius = (size * { "sharp" => 0.1, "round" => 0.35 }.fetch(@theme.corners, 0.2)).round
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
