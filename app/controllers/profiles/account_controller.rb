class Profiles::AccountController < ApplicationController
  layout 'profiles'

  before_action :set_user

  def show; end

  def update; end

  private

  def update_password_params
    params.require(:user).permit(:password, :password_confirmation, :current_password)
  end

  def set_user
    @user = current_user
  end
end
