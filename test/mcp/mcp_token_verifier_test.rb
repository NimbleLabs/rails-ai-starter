require "test_helper"
require_relative "../support/mcp_helpers"

class McpTokenVerifierTest < ActiveSupport::TestCase
  include McpHelpers

  test "a live token becomes the user, client and scopes it was issued for" do
    user = users(:two)
    raw = mcp_token_for(user)
    stored = Doorkeeper::AccessToken.by_token(raw)

    access_token = McpTokenVerifier.new.verify(raw)

    assert_equal user.id.to_s, access_token.subject
    assert_equal stored.application.uid, access_token.client_id
    assert_equal [ "mcp" ], access_token.scopes
    assert_equal stored.expires_at.to_i, access_token.expires_at
    assert_equal McpServer.resource_url, access_token.resource
    assert_not_includes access_token.inspect, raw, "the token never ends up in logs"
  end

  test "unknown, expired and revoked tokens are invalid" do
    expired = mcp_token_for(users(:two), created_at: 2.hours.ago)
    revoked = mcp_token_for(users(:two), revoked_at: 1.minute.ago)

    [ "unknown", expired, revoked ].each do |raw|
      assert_raises(MCP::Server::OAuth::InvalidTokenError) { McpTokenVerifier.new.verify(raw) }
    end
  end
end
