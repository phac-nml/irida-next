# frozen_string_literal: true

module Pathogen
  # Preview for TabsNav component
  # Server-side navigation with tab-like appearance
  class TabsNavPreview < ViewComponent::Preview
    # Basic navigation with two tabs
    # @label Basic
    def default
      render(Pathogen::TabsNav.new(id: 'demo-nav', label: 'Navigation example')) do |nav|
        nav.with_tab(
          id: 'all',
          text: 'All Items',
          href: '#all',
          selected: true
        )
        nav.with_tab(
          id: 'personal',
          text: 'Personal',
          href: '#personal'
        )
      end
    end

    # Navigation with three tabs
    # @label Three Tabs
    def three_tabs
      render(Pathogen::TabsNav.new(id: 'demo-nav-three', label: 'Three tab navigation')) do |nav|
        nav.with_tab(id: 'overview', text: 'Overview', href: '#overview', selected: true)
        nav.with_tab(id: 'details', text: 'Details', href: '#details')
        nav.with_tab(id: 'history', text: 'History', href: '#history')
      end
    end

    # Navigation with right content area
    # @label With Right Content
    def with_right_content
      render(Pathogen::TabsNav.new(id: 'demo-nav-content', label: 'Navigation with controls')) do |nav|
        nav.with_tab(id: 'all', text: 'All Projects', href: '#all', selected: true)
        nav.with_tab(id: 'personal', text: 'My Projects', href: '#personal')
        nav.with_right_content do
          tag.div(class: 'flex gap-2') do
            tag.input(type: 'search', placeholder: 'Search...',
                      class: 'px-3 py-2 border border-slate-300 rounded-md text-sm') +
              tag.button('Filter', class: 'px-3 py-2 bg-slate-100 text-slate-700 rounded-md text-sm font-medium')
          end
        end
      end
    end

    # Navigation with no selection (valid use case)
    # @label No Selection
    def no_selection
      render(Pathogen::TabsNav.new(id: 'demo-nav-none', label: 'Navigation without selection')) do |nav|
        nav.with_tab(id: 'all', text: 'All Items', href: '#all')
        nav.with_tab(id: 'personal', text: 'Personal', href: '#personal')
      end
    end

    # Navigation with longer tab labels
    # @label Long Labels
    def long_labels
      render(Pathogen::TabsNav.new(id: 'demo-nav-long', label: 'Navigation with longer text')) do |nav|
        nav.with_tab(id: 'analytics', text: 'Analytics Dashboard', href: '#analytics', selected: true)
        nav.with_tab(id: 'reports', text: 'Monthly Reports', href: '#reports')
        nav.with_tab(id: 'settings', text: 'Configuration Settings', href: '#settings')
      end
    end
  end
end
