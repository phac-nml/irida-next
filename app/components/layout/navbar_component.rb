# frozen_string_literal: true

module Layout
  class NavbarComponent < ViewComponent::Base
    def initialize(user:, **system_arguments)
      @user = user
      @system_arguments = system_arguments
    end
  end
end
