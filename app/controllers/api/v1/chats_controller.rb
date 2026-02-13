class Api::V1::ChatsController < ApplicationController
  before_action :authenticate_user_or_token
  before_action :set_chat, only: [:show, :update, :destroy, :messages]

  def index
    @chats = current_user.chats.order(updated_at: :desc)
    render json: @chats.map { |chat| chat_json(chat) }
  end

  def show
    render json: chat_json(@chat, include_messages: true)
  end

  def create
    @chat = current_user.chats.new(title: params[:title])
    assign_model_if_present

    if @chat.save
      render json: chat_json(@chat), status: :created
    else
      render json: { errors: @chat.errors }, status: :unprocessable_entity
    end
  end

  def update
    @chat.title = params[:title] if params[:title].present?
    assign_model_if_present

    if @chat.save
      render json: chat_json(@chat)
    else
      render json: { errors: @chat.errors }, status: :unprocessable_entity
    end
  end

  def destroy
    @chat.destroy!
    head :no_content
  end

  def messages
    msgs = @chat.messages.order(:created_at)
    render json: msgs.map { |m| message_json(m) }
  end

  private

  def set_chat
    @chat = current_user.chats.find(params[:id])
  end

  # Accepts model_id as the LLM model string (e.g. "gpt-5-mini")
  # and uses ruby_llm's built-in model= setter to resolve it.
  def assign_model_if_present
    model_id = params[:model_id]
    return unless model_id.present?

    @chat.model = model_id
  end

  def chat_json(chat, include_messages: false)
    model_record = chat.model_association
    data = {
      id: chat.id,
      title: chat.title,
      model_id: model_record&.model_id,
      model_name: model_record&.name,
      created_at: chat.created_at,
      updated_at: chat.updated_at
    }
    if include_messages
      data[:messages] = chat.messages.order(:created_at).map { |m| message_json(m) }
    end
    data
  end

  def message_json(msg)
    {
      id: msg.id,
      role: msg.role,
      content: msg.content,
      created_at: msg.created_at
    }
  end
end
