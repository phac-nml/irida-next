# frozen_string_literal: true

class BreadcrumbComponentPreview < ViewComponent::Preview
  def breadcrumb_without_crumbs
    render Viral::BreadcrumbComponent.new(route: Route.new(name: 'Group / Project', path: 'group/project'))
  end

  def breadcrumb_with_crumbs
    render Viral::BreadcrumbComponent.new(
      route: Route.new(name: 'Borrelia burgdorferi / Project Name', path: 'group/project'),
      context_crumbs: [{ name: 'A new group name',
                         path: '/groups' }]
    )
  end
end
