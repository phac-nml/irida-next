# frozen_string_literal: true

module Navigation
  # Main navigation bar component
  class NavbarComponent < ViewComponent::Base
    def initialize(user:)
      @user = user
    end
  end
end
