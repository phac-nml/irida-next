class Profiles::AccountsController < ApplicationController
  layout 'profiles'

  before_action :set_user

  def show; end

  def destroy; end

  private

  def set_user
    @user = current_user
  end
end
