# frozen_string_literal: true

# Devise sessions controller
class SessionsController < Devise::SessionsController
  layout 'devise'

  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  def new
    super do
      if resource_class.omniauth_providers.empty?
        render :new_with_no_providers
      else
        @local_account = params[:local]

        render :new_with_providers
      end
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
end
