# Base class for this app's MCP tools. A tool is a class with a description,
# an input schema and a `self.call` (see HelloTool). Every request to /mcp is
# made with a user's OAuth token, so a tool always knows who it is acting for.
class ApplicationTool < MCP::Tool
  # The user who approved the client making this request.
  def self.current_user(server_context)
    User.find(server_context.auth_info.subject)
  end
end
