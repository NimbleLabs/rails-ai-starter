class BrandingController < ApplicationController
  skip_before_action :verify_authenticity_token

  # GET /favicon.svg — the brand mark as a scalable favicon, colored to match the app.
  def favicon
    config = AppConfig.current
    theme = config.theme
    radius = case theme.corners
    when "sharp" then 2
    when "round" then 10
    else 6
    end

    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 32 32">
        <rect width="32" height="32" rx="#{radius}" fill="#{theme.primary}"/>
        <text x="16" y="16" text-anchor="middle" dominant-baseline="central"
              font-family="system-ui, sans-serif" font-weight="800"
              font-size="#{font_size_for(config.short_name)}" fill="#{theme.on_primary}">#{ERB::Util.html_escape(config.short_name)}</text>
      </svg>
    SVG

    expires_in 1.hour, public: true
    render plain: svg, content_type: "image/svg+xml"
  end

  # GET /og-image.png — a 1200x630 branded image for link previews.
  # Query params: ?title=...&description=... for page-specific cards.
  def og_image
    config = AppConfig.current
    theme = config.theme
    title = (params[:title].presence || config.name).truncate(80)
    description = (params[:description].presence || config.tagline).truncate(160)
    radius = case theme.corners
    when "sharp" then 0
    when "round" then 32
    else 16
    end

    svg = <<~SVG
      <svg xmlns="http://www.w3.org/2000/svg" width="1200" height="630" viewBox="0 0 1200 630">
        <rect width="1200" height="630" fill="#fffaf0"/>
        <rect x="40" y="40" width="1120" height="550" rx="#{radius}" fill="#{theme.primary}" opacity="0.06"/>
        <rect x="60" y="340" width="1080" height="4" rx="2" fill="#{theme.primary}" opacity="0.15"/>
        #{brand_mark_svg(config, theme, 80, 80, 80)}
        <text x="180" y="115" font-family="system-ui, sans-serif" font-weight="800"
              font-size="36" fill="#1c1410">#{ERB::Util.html_escape(config.name)}</text>
        <text x="80" y="240" font-family="system-ui, sans-serif" font-weight="700"
              font-size="#{title_font_size(title)}" fill="#1c1410">#{wrap_text(ERB::Util.html_escape(title), 80, 240, title_font_size(title), 40, 900)}</text>
        <text x="80" y="390" font-family="system-ui, sans-serif" font-weight="400"
              font-size="24" fill="#78716c">#{wrap_text(ERB::Util.html_escape(description), 80, 390, 24, 32, 1000)}</text>
        <rect x="80" y="520" width="120" height="6" rx="3" fill="#{theme.primary}"/>
      </svg>
    SVG

    expires_in 1.hour, public: true
    render plain: svg, content_type: "image/svg+xml"
  end

  private

  def font_size_for(short_name)
    case short_name.length
    when 1 then 20
    when 2 then 16
    else 13
    end
  end

  def brand_mark_svg(config, theme, x, y, size)
    radius = case theme.corners
    when "sharp" then (size * 0.1).round
    when "round" then (size * 0.35).round
    else (size * 0.2).round
    end
    text_size = case config.short_name.length
    when 1 then (size * 0.55).round
    when 2 then (size * 0.42).round
    else (size * 0.33).round
    end
    cx = x + size / 2
    cy = y + size / 2

    <<~SVG
      <rect x="#{x}" y="#{y}" width="#{size}" height="#{size}" rx="#{radius}" fill="#{theme.primary}"/>
      <text x="#{cx}" y="#{cy}" text-anchor="middle" dominant-baseline="central"
            font-family="system-ui, sans-serif" font-weight="800"
            font-size="#{text_size}" fill="#{theme.on_primary}">#{ERB::Util.html_escape(config.short_name)}</text>
    SVG
  end

  def title_font_size(title)
    return 48 if title.length <= 30
    return 40 if title.length <= 50
    32
  end

  def wrap_text(text, start_x, start_y, font_size, line_height, max_width)
    chars_per_line = (max_width / (font_size * 0.55)).to_i
    words = text.split
    lines = []
    current = ""

    words.each do |word|
      test = current.empty? ? word : "#{current} #{word}"
      if test.length > chars_per_line && !current.empty?
        lines << current
        current = word
      else
        current = test
      end
    end
    lines << current unless current.empty?

    lines.first(3).each_with_index.map do |line, i|
      y = start_y + (i * line_height)
      display = (i == 2 && lines.length > 3) ? "#{line.truncate(chars_per_line - 3)}..." : line
      if i == 0
        display
      else
        %(<tspan x="#{start_x}" dy="#{line_height}">#{display}</tspan>)
      end
    end.join
  end
end
