# frozen_string_literal: true

module Layout
  # This component is used to render the layout of the application.
  class LayoutComponent < Component
    renders_one :sidebar, Navigation::NavigationComponent
    renders_one :body

    def initialize(user:, **system_arguments)
      @user = user
      @system_arguments = system_arguments
    end
  end
end
