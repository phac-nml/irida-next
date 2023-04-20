# frozen_string_literal: true

module Layout
  # Top level navigation bar
  class NavbarComponent < Component
    attr_reader :user

    def initialize(user:, **system_arguments)
      @user = user
      @system_arguments = system_arguments
    end
  end
end
