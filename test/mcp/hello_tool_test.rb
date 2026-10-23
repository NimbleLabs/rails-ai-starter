require "test_helper"

class HelloToolTest < ActiveSupport::TestCase
  setup { @user = users(:two) }

  test "greets the name it is given and names the connected account" do
    assert_equal "Hello, Ada! You're connected to #{AppConfig.current.name} as user@example.com.",
                 text_of(HelloTool.call(name: "  Ada  ", server_context: context_for(@user)))
  end

  test "greets the signed-in user when no name is given" do
    [ nil, "", "   " ].each do |name|
      assert_match(/\AHello, Regular User!/, text_of(HelloTool.call(name: name, server_context: context_for(@user))))
    end
  end

  test "falls back to a plain hello for a user with no name" do
    @user.update_column(:name, nil)

    assert_match(/\AHello, there!/, text_of(HelloTool.call(server_context: context_for(@user))))
  end

  test "acts for the user behind the token, whoever the name says" do
    admin = users(:one)

    assert_includes text_of(HelloTool.call(name: "Regular User", server_context: context_for(admin))), admin.email
  end

  test "is advertised as a read-only tool called hello" do
    definition = HelloTool.to_h

    assert_equal "hello", definition[:name]
    assert_equal HelloTool::MAX_NAME_LENGTH, definition.dig(:inputSchema, :properties, :name, :maxLength)
    assert_equal true, definition.dig(:annotations, :readOnlyHint)
    assert_equal false, definition.dig(:annotations, :destructiveHint)
  end

  private

  # What a tool reads from the SDK's server context: the verified token.
  def context_for(user)
    Struct.new(:auth_info).new(
      MCP::Server::OAuth::AccessToken.new(token: "token", subject: user.id.to_s, scopes: [ McpServer::SCOPE ])
    )
  end

  def text_of(response)
    response.content.first[:text]
  end
end
