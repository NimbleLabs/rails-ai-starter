# Bridges Rails' built-in error reporter (Rails.error) into the Log model.
#
# Rails 8 already routes the right things through Rails.error:
#   * ActionDispatch::Executor — unhandled request exceptions, EXCLUDING anything
#     in ActionDispatch's rescue_responses (RecordNotFound → 404,
#     ParameterMissing → 400, InvalidAuthenticityToken → 422, RoutingError, ...).
#   * ActiveJob — only once retries are exhausted or the job is discarded.
#   * Explicit `Rails.error.report(e, handled: true, context: {...})` calls.
#
# That is exactly the "surgical" set we want. Anything noisier (bots hitting
# bad URLs, expired sessions, validation failures) never reaches here.
class LogErrorSubscriber
  # Belt-and-braces: never log these even if something reports them explicitly.
  IGNORED = %w[
    ActiveRecord::RecordNotFound
    ActionController::RoutingError
    ActionController::InvalidAuthenticityToken
    ActionController::InvalidCrossOriginRequest
    ActionController::ParameterMissing
    ActionController::BadRequest
    ActionController::UnknownFormat
    ActionController::UnknownHttpMethod
    ActionController::MethodNotAllowed
    ActionDispatch::Http::MimeNegotiation::InvalidType
    ActionDispatch::Http::Parameters::ParseError
    Rack::QueryParser::InvalidParameterError
    Rack::QueryParser::ParameterTypeError
  ].freeze

  SOURCE_MAP = {
    "application.action_dispatch" => "web",
    "application.active_job"      => "job"
  }.freeze

  def report(error, handled:, severity:, context:, source: nil)
    return if ignored?(error)

    ctx = (context || {}).to_h.deep_stringify_keys
    ctx["handled"] = handled
    ctx["reporter_source"] = source if source.present?

    Log.record(
      error,
      level:   level_for(severity, handled),
      source:  SOURCE_MAP[source] || ctx["source"].presence || (ctx["request_id"].present? ? "web" : "app"),
      context: ctx
    )
  rescue Interrupt, SignalException, SystemExit
    raise
  rescue Exception => e
    # Never let the logger itself raise inside the error reporter.
    Rails.logger.error("[LogErrorSubscriber] #{e.class}: #{e.message}")
  end

  private

  def ignored?(error)
    klass = error.class
    IGNORED.any? { |name| klass.name == name || (Object.const_defined?(name) && klass <= Object.const_get(name)) }
  end

  def level_for(severity, handled)
    case severity
    when :info    then :info
    when :warning then :warn
    else handled ? :error : :error
    end
  end
end
