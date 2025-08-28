class ContactsController < ApplicationController
  before_action :authenticate_user!, except: %i[ new create ]
  before_action :ensure_admin, except: %i[ new create ]
  before_action :set_contact, only: %i[ show edit update destroy ]

  # GET /contacts or /contacts.json
  def index
    @contacts = Contact.all
  end

  # GET /contacts/1 or /contacts/1.json
  def show
  end

  # GET /contacts/new
  def new
    @contact = Contact.new
  end

  # GET /contacts/1/edit
  def edit
  end

  # POST /contacts or /contacts.json
  def create_action_plan
    @contact = Contact.find_or_initialize_by(email: contact_params[:email])
    @contact.assign_attributes(contact_params)

    if @contact.save
      prompt = "#{AppConstants::ACTION_PLAN_PROMPT} #{@contact.biggest_problem}"
      prompt += AppConstants::ACTION_PLAN_PROMPT_END
      @chat = Chat.new(ai_model_id: "o1-mini", user_prompt: prompt, is_public: true)
      @chat.user = User.first
      @chat.contact = @contact

      begin
        @chat_service = ChatService.new(@chat)
        if @chat_service.save_chat
          chat_message = @chat_service.start_chat
          update_usage_session(chat_message)
          @chat.reload
          action_plan = @chat.first_ai_response.content
          ContactMailer.with(contact: @contact, action_plan: action_plan).ai_action_plan.deliver_later
          SlackService.system_alert_service.action_plan_event(@contact)
          render json: { action_plan: action_plan }, status: :created
          return
        else
          render json: @chat.errors, status: :unprocessable_entity
        end
      rescue => e
        @chat.destroy
        Rollbar.error(e)

        render json: {
          error: "API Error",
          message: e.message
        }, status: :service_unavailable
      end
    else
      render json: { errors: @contact.errors }, status: :unprocessable_entity
    end
  end
  def create
    @contact = Contact.new(contact_params)

    respond_to do |format|
      if verify_recaptcha(model: @contact) && @contact.save
        SlackService.system_alert_service.contact_form_event(@contact)
        format.html { redirect_to services_path, notice: 'Thank you for your message. We\'ll be in touch soon!' }
        format.json { render json: { message: 'Thank you for your message. We\'ll be in touch soon!' }, status: :created }
      else
        format.html { redirect_to services_path, alert: 'There was a problem sending your message.' }
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /contacts/1 or /contacts/1.json
  def update
    respond_to do |format|
      if @contact.update(contact_params)
        format.html { redirect_to @contact, notice: "Contact was successfully updated." }
        format.json { render :show, status: :ok, location: @contact }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @contact.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /contacts/1 or /contacts/1.json
  def destroy
    @contact.destroy!

    respond_to do |format|
      format.html { redirect_to contacts_path, status: :see_other, notice: "Contact was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_contact
      @contact = Contact.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def contact_params
      params.require(:contact).permit(:name, :email, :phone, :company_name, :budget_range, :message, :biggest_problem)
    end
end
