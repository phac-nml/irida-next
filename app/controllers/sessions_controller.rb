# frozen_string_literal: true

# Devise sessions controller
class SessionsController < Devise::SessionsController
  layout 'devise'
  before_action :page_title

  # before_action :configure_sign_in_params, only: [:create]
  prepend_before_action :ensure_password_authentication_enabled!,
                        if: -> { action_name == 'create' && password_based_login? }

  # GET /resource/sign_in
  def new
    super do
      @local_account = params[:local] if Irida::CurrentSettings.password_authentication_enabled?

      return
    end
  end

  # POST /resource/sign_in
  def create
    super do
      resource.update!(locale: params[:locale]) if params[:locale].present?
    end
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def page_title
    @title = t(:'devise.sessions.new.login')
  end

  def ensure_password_authentication_enabled!
    return if Irida::CurrentSettings.password_authentication_enabled?

    respond_to do |format|
      format.html { render 'shared/error/not_authorized', status: :forbidden, locals: { authorization_message: '' } }
      format.any { head :forbidden }
    end
  end

  def password_based_login?
    user_params[:email].present? && user_params[:password].present?
  end

  def user_params
    params.expect(user: %i[email password remember_me])
  end
end
