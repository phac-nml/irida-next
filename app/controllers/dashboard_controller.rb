# frozen_string_literal: true

# Controller actions for Dashboard page
class DashboardController < ApplicationController
  def index
    redirect_to projects_path
  end
end
