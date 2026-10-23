# The MCP server at /mcp (see app/mcp/mcp_server.rb). A tool that raises is
# answered with a JSON-RPC error rather than a 500, so it is reported to the
# internal Logs from here instead. McpServer.report_exception decides what is
# worth a human's attention.
MCP.configure do |config|
  config.exception_reporter = ->(error, context) { McpServer.report_exception(error, context) }
end
