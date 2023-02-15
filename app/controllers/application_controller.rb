# frozen_string_literal: true

# Main application controller
class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
end
