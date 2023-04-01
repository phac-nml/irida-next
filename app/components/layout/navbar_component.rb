# frozen_string_literal: true

module Layout
  # Main navigation bar component
  class NavbarComponent < ViewComponent::Base
    def initialize(user:)
      @user = user
    end
  end
end
