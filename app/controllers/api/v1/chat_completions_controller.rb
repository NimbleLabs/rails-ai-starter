class Api::V1::ChatCompletionsController < ApplicationController
  include ActionController::Live
  skip_forgery_protection

  before_action :authenticate_user_or_token
  before_action :set_chat

  def create
    response.headers["Content-Type"] = "text/event-stream"
    response.headers["Cache-Control"] = "no-cache"
    response.headers["X-Accel-Buffering"] = "no"

    message_text = params[:message] || params.dig(:messages, -1, :content)
    unless message_text.present?
      response.stream.write("data: #{{ error: 'Message is required' }.to_json}\n\n")
      return
    end

    @chat.ask(message_text) do |chunk|
      content = chunk.content.to_s
      next if content.empty?

      data = { content: content }
      response.stream.write("data: #{data.to_json}\n\n")
    end

    # Auto-generate title from first user message if chat has no title
    if @chat.title.blank? && @chat.messages.where(role: "user").count == 1
      @chat.update(title: message_text.truncate(80))
    end

    response.stream.write("data: #{{ done: true }.to_json}\n\n")
  rescue ActionController::Live::ClientDisconnected
    # Client disconnected, nothing to do
  rescue => e
    Rails.logger.error("Chat completion error: #{e.message}")
    begin
      response.stream.write("data: #{{ error: e.message }.to_json}\n\n")
    rescue
      # Stream may already be closed
    end
  ensure
    response.stream.close
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:chat_id])
  end
end
