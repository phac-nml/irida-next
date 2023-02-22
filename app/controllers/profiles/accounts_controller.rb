class Profiles::AccountsController < ApplicationController
  layout 'profiles'

  before_action :set_user

  def show; end

  def destroy
    @user.destroy
    redirect_to root_path
  end

  private

  def set_user
    @user = current_user
  end
end
