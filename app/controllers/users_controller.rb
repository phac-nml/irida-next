# frozen_string_literal: true

# Controller actions for Users
class UsersController < ApplicationController
  before_action :user

  def show
    authorize! @user
    respond_to do |format|
      format.html do
        render 'users/show'
      end
    end
  end

  private

  def user
    @user ||= Namespaces::UserNamespace.find_by_full_path(params[:username]).owner # rubocop:disable Rails/DynamicFindBy
  end
end
