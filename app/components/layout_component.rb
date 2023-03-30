# frozen_string_literal: true

# This component is used to render the layout of the application.
class LayoutComponent < Component
  renders_one :sidebar, Navigation::NavigationComponent
  renders_one :body

  def initialize(**system_arguments)
    @system_arguments = system_arguments
  end
end
