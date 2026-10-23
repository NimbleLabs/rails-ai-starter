module OauthHelper
  # Where the consent page says the user goes after approving. Any client can
  # register under any name, so this is what tells "Claude" (claude.ai) from
  # an impostor: the website's host, "an app on this computer" for a local
  # client like Claude Code, or the app named by a native client's URI scheme.
  def oauth_redirect_destination(redirect_uri)
    uri = URI.parse(redirect_uri)
    if %w[http https].include?(uri.scheme)
      local = uri.host == "localhost" || Doorkeeper::OAuth::Helpers::URIChecker.loopback_uri?(uri)
      local ? "an app on this computer" : uri.host
    else
      "the #{uri.scheme} app"
    end
  rescue URI::InvalidURIError
    redirect_uri
  end

  # A plain sentence for an OAuth error code, for the error page. Doorkeeper's
  # own description is written for the client's developer.
  def oauth_error_message(error)
    case error.to_s
    when "invalid_client" then "The app that sent you here isn't registered with #{app_config.name}."
    when "invalid_redirect_uri" then "The app asked to send you somewhere it never registered."
    when "invalid_scope" then "The app asked for access #{app_config.name} doesn't offer."
    else "The app's request was missing something or wasn't valid."
    end
  end
end
