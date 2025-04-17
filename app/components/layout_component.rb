# frozen_string_literal: true

# Overall layout component
class LayoutComponent < Component
  attr_reader :layout, :user

  renders_one :sidebar, Layout::SidebarComponent
  renders_one :body
  renders_one :breadcrumb, Viral::BreadcrumbComponent
  renders_one :language_selection, Layout::LanguageSelectionComponent

  def initialize(user:, fixed: true, **system_arguments)
    @user = user
    @layout = fixed ? 'container mx-auto' : ''
    @system_arguments = system_arguments
  end
end
