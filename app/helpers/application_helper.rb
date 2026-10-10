module ApplicationHelper
  def resource_name
    :user
  end

  # config/app.yml: the app's name, tagline and look. See AppConfig.
  def app_config
    AppConfig.current
  end

  # The square initials mark that stands in for a logo.
  def brand_mark(size_classes = "w-8 h-8 text-xs")
    tag.span(app_config.short_name, class: "brand-mark #{size_classes}", aria: { hidden: true })
  end
end
