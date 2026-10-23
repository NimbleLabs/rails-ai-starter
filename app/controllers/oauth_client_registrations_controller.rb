# Dynamic client registration (RFC 7591): how an MCP client like Claude gets a
# client_id the first time someone connects it. Anyone may register, as the
# protocol intends. A registration grants nothing by itself: the user still has
# to sign in and approve on the consent page, which shows where the client will
# send them afterwards.
class OauthClientRegistrationsController < ActionController::API
  AUTH_METHODS = %w[client_secret_basic client_secret_post none].freeze
  GRANT_TYPES = %w[authorization_code refresh_token].freeze
  MAX_REDIRECT_URIS = 10
  MAX_NAME_LENGTH = 100
  DEFAULT_NAME = "MCP client".freeze

  # Generous, because one service (claude.ai, say) registers for each of its
  # users from a handful of addresses. It only stops a script in a loop.
  rate_limit to: 30, within: 1.minute

  def create
    metadata = JSON.parse(request.raw_post)
    return invalid("invalid_client_metadata", "The request body must be a JSON object.") unless metadata.is_a?(Hash)

    redirect_uris = metadata["redirect_uris"]
    unless valid_redirect_uris?(redirect_uris)
      return invalid("invalid_redirect_uri", "redirect_uris must list 1 to #{MAX_REDIRECT_URIS} URLs.")
    end

    auth_method = metadata.fetch("token_endpoint_auth_method", "client_secret_basic")
    unless AUTH_METHODS.include?(auth_method)
      return invalid("invalid_client_metadata", "token_endpoint_auth_method must be one of: #{AUTH_METHODS.join(", ")}.")
    end
    unless subset?(metadata.fetch("grant_types", GRANT_TYPES), GRANT_TYPES)
      return invalid("invalid_client_metadata", "Only these grant_types are supported: #{GRANT_TYPES.join(", ")}.")
    end
    unless subset?(metadata.fetch("response_types", %w[code]), %w[code])
      return invalid("invalid_client_metadata", "Only the code response_type is supported.")
    end

    application = Doorkeeper::Application.new(
      name: metadata["client_name"].to_s.squish.truncate(MAX_NAME_LENGTH).presence || DEFAULT_NAME,
      redirect_uri: redirect_uris.join("\n"),
      scopes: McpServer::SCOPE,
      confidential: auth_method != "none"
    )
    unless application.save
      return invalid("invalid_redirect_uri", application.errors.full_messages.to_sentence)
    end

    render status: :created, json: {
      client_id: application.uid,
      client_secret: (application.plaintext_secret if application.confidential?),
      client_secret_expires_at: (0 if application.confidential?),
      client_id_issued_at: application.created_at.to_i,
      client_name: application.name,
      redirect_uris: redirect_uris,
      token_endpoint_auth_method: auth_method,
      grant_types: GRANT_TYPES,
      response_types: %w[code],
      scope: McpServer::SCOPE
    }.compact
  rescue JSON::ParserError
    invalid("invalid_client_metadata", "The request body must be a JSON object.")
  end

  private

  # Doorkeeper keeps a client's redirect URIs in one whitespace-separated
  # column, so a URI containing whitespace would quietly become two. The
  # out-of-band "urn:" URIs would show the code on our own page for someone
  # to copy, which only helps phishing.
  def valid_redirect_uris?(uris)
    uris.is_a?(Array) && uris.size.between?(1, MAX_REDIRECT_URIS) && uris.all? do |uri|
      uri.is_a?(String) && uri.present? && !uri.match?(/\s/) &&
        !Doorkeeper::OAuth::Helpers::URIChecker.oob_uri?(uri)
    end
  end

  def subset?(values, allowed)
    values.is_a?(Array) && values.all? { |value| allowed.include?(value) }
  end

  def invalid(error, description)
    render status: :bad_request, json: { error: error, error_description: description }
  end
end
