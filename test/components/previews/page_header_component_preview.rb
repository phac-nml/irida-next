# frozen_string_literal: true

class PageHeaderComponentPreview < ViewComponent::Preview
  def default
    render Viral::PageHeaderComponent.new(
      title: 'Page header',
      subtitle: 'This is a page header'
    )
  end

  def with_icon
    render Viral::PageHeaderComponent.new(
      title: 'Page header',
      subtitle: 'This is a page header'
    ) do |component|
      component.icon(name: 'users', classes: 'h-14 w-14 text-primary-700')
    end
  end

  def with_buttons
    render Viral::PageHeaderComponent.new(
      title: 'Page header',
      subtitle: 'This is a page header'
    ) do |component|
      component.buttons do
        content_tag(:button, 'Create New Project', class: 'btn btn-primary')
      end
    end
  end
end
