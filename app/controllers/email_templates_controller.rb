class EmailTemplatesController < ApplicationController
  before_action :authenticate_user!
  before_action :ensure_admin
  before_action :set_email_template, only: %i[ show send_to_list edit update destroy ]

  # GET /email_templates or /email_templates.json
  def index
    @email_templates = EmailTemplate.all
  end

  def send_to_list
    @email_template = EmailTemplate.find(params[:id])
    SendEmailTemplateJob.perform_later(@email_template.id)
    
    render json: { message: "Email template will be sent to the list." }
  end

  # GET /email_templates/1 or /email_templates/1.json
  def show
  end

  # GET /email_templates/new
  def new
    @email_template = EmailTemplate.new
  end

  # GET /email_templates/1/edit
  def edit
  end

  # POST /email_templates or /email_templates.json
  def create
    @email_template = EmailTemplate.new(email_template_params)

    respond_to do |format|
      if @email_template.save
        format.html { redirect_to @email_template, notice: "Email template was successfully created." }
        format.json { render :show, status: :created, location: @email_template }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @email_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /email_templates/1 or /email_templates/1.json
  def update
    respond_to do |format|
      if @email_template.update(email_template_params)
        format.html { redirect_to @email_template, notice: "Email template was successfully updated." }
        format.json { render :show, status: :ok, location: @email_template }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @email_template.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /email_templates/1 or /email_templates/1.json
  def destroy
    @email_template.destroy!

    respond_to do |format|
      format.html { redirect_to email_templates_path, status: :see_other, notice: "Email template was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_email_template
      @email_template = EmailTemplate.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def email_template_params
      params.require(:email_template).permit(:subject, :body, :send_group)
    end
end
