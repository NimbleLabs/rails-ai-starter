# The starter's example tool. It greets you and says which account the
# connection uses, which proves the whole chain works: discovery, OAuth, the
# token, and the user behind it. Copy it to make a tool of your own, then add
# the new class to McpServer::TOOLS.
class HelloTool < ApplicationTool
  MAX_NAME_LENGTH = 100

  tool_name "hello"
  title "Say hello"
  description "Says hello and tells you which account this connection uses."
  input_schema(
    properties: {
      name: {
        type: "string",
        maxLength: MAX_NAME_LENGTH,
        description: "Who to greet. Leave it out to greet the signed-in user."
      }
    }
  )
  annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

  def self.call(server_context:, name: nil)
    user = current_user(server_context)
    greeting = name.to_s.strip.presence || user.name.presence || "there"

    MCP::Tool::Response.new([
      { type: "text", text: "Hello, #{greeting}! You're connected to #{AppConfig.current.name} as #{user.email}." }
    ])
  end
end
