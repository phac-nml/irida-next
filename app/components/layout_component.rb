# frozen_string_literal: true

# Overall layout component
class LayoutComponent < Component
  include Turbo::FramesHelper

  attr_reader :user

  renders_one :sidebar, Layout::SidebarComponent
  renders_one :body

  def initialize(user:, **system_arguments)
    @user = user
    @system_arguments = system_arguments
  end
end
