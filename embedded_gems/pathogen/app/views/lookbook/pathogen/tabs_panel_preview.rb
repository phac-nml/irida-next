# frozen_string_literal: true

class Lookbook::Pathogen::TabsPanelPreview < ViewComponent::Preview
  # @!group Basic Usage
  # @label Default
  # @description Basic tabs panel with underline style
  def default
    render Pathogen::TabsPanel.new(id: 'basic-tabs', label: 'Basic Navigation') do |panel|
      panel.with_tab(selected: true, controls: 'tab-1', id: 'tab-1', href: '#', tablist_id: 'basic-tabs',
                     text: 'Dashboard')
      panel.with_tab(controls: 'tab-2', id: 'tab-2', href: '#', tablist_id: 'basic-tabs', text: 'Settings')
      panel.with_tab(controls: 'tab-3', id: 'tab-3', href: '#', tablist_id: 'basic-tabs', text: 'Profile')
    end
  end

  # @label With Icons
  # @description Tabs with icons for better visual hierarchy
  def with_icons
    render Pathogen::TabsPanel.new(id: 'icon-tabs', label: 'Navigation with Icons') do |panel|
      panel.with_tab(selected: true, controls: 'icon-tab-1', id: 'icon-tab-1', href: '#', tablist_id: 'icon-tabs',
                     text: 'Home')
      panel.with_tab(controls: 'icon-tab-2', id: 'icon-tab-2', href: '#', tablist_id: 'icon-tabs', text: 'Settings')
      panel.with_tab(controls: 'icon-tab-3', id: 'icon-tab-3', href: '#', tablist_id: 'icon-tabs', text: 'Profile')
    end
  end

  # @label Custom Type
  # @description Tabs with default style instead of underline
  def custom_type
    render Pathogen::TabsPanel.new(id: 'custom-tabs', type: 'default', label: 'Custom Style Tabs') do |panel|
      panel.tab(selected: true, controls: 'custom-tab-1') do
        'Analytics'
      end
      panel.tab(controls: 'custom-tab-2') do
        'Reports'
      end
      panel.tab(controls: 'custom-tab-3') do
        'Export'
      end
    end
  end

  # @label With Badges
  # @description Tabs with notification badges
  def with_badges
    render Pathogen::TabsPanel.new(id: 'badge-tabs', label: 'Tabs with Notifications') do |panel|
      panel.tab(selected: true, controls: 'badge-tab-1') do
        tag.div(class: 'flex items-center gap-2') do
          'Messages'
          tag.span(class: 'bg-red-100 text-red-800 text-xs font-medium px-2.5 py-0.5 rounded-full') do
            '3'
          end
        end
      end
      panel.tab(controls: 'badge-tab-2') do
        tag.div(class: 'flex items-center gap-2') do
          'Notifications'
          tag.span(class: 'bg-blue-100 text-blue-800 text-xs font-medium px-2.5 py-0.5 rounded-full') do
            'New'
          end
        end
      end
      panel.tab(controls: 'badge-tab-3') do
        'Settings'
      end
    end
  end

  # @label Responsive
  # @description Tabs that adapt to different screen sizes
  def responsive
    render Pathogen::TabsPanel.new(
      id: 'responsive-tabs',
      label: 'Responsive Navigation',
      body_arguments: { class: 'flex flex-wrap md:flex-nowrap' }
    ) do |panel|
      panel.tab(selected: true, controls: 'responsive-tab-1') do
        'Overview'
      end
      panel.tab(controls: 'responsive-tab-2') do
        'Statistics'
      end
      panel.tab(controls: 'responsive-tab-3') do
        'Analytics'
      end
      panel.tab(controls: 'responsive-tab-4') do
        'Reports'
      end
    end
  end

  # @label With Custom Classes
  # @description Tabs with custom styling
  def with_custom_classes
    render Pathogen::TabsPanel.new(
      id: 'custom-class-tabs',
      label: 'Custom Styled Tabs',
      body_arguments: { class: 'flex flex-wrap -mb-px text-sm font-medium text-center text-slate-500 border-b border-slate-200 dark:border-slate-700 dark:text-slate-400 w-full bg-slate-50 dark:bg-slate-800 rounded-t-lg' }
    ) do |panel|
      panel.tab(selected: true, controls: 'custom-class-tab-1') do
        'Active'
      end
      panel.tab(controls: 'custom-class-tab-2') do
        'Pending'
      end
      panel.tab(controls: 'custom-class-tab-3') do
        'Archived'
      end
    end
  end
  # @!endgroup
end
