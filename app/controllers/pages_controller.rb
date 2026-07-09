# frozen_string_literal: true

# Controller actions for Pages
class PagesController < ApplicationController
  def accessibility_statement
    not_found unless Flipper.enabled?(:accessibility_statement, current_user)
  end
end
