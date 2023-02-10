# frozen_string_literal: true

# Controller actions for Dashboard page
class DashboardController < ApplicationController
  layout 'irida'

  def index
    @dashboard_props = { name: 'Stranger Barney' }
  end
end
