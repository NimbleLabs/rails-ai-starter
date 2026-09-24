RubyLLM.configure do |config|
  config.anthropic_api_key = ENV.fetch("ANTHROPIC_API_KEY", Rails.application.credentials.dig(:anthropic_api_key))
  config.openai_api_key = ENV.fetch("OPENAI_API_KEY", Rails.application.credentials.dig(:openai_api_key))

  # Claude is the default; pass `model:` to use another (e.g. "gpt-5-mini").
  config.default_model = "claude-sonnet-5"
end
