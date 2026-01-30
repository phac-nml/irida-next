# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class LinkTest < ViewComponent::TestCase
    def test_renders_a_link
      url = '/samples'
      link_text = 'content'
      render_inline(Pathogen::Link.new(href: url)) { link_text }
      assert_component_rendered
      assert_selector "a[href='#{url}']", text: link_text
      assert_no_selector "a[aria-label='#{I18n.t('pathogen.link.aria-label', content: link_text)}']"
    end

    def test_renders_an_external_link
      url = 'http://irida-next.com'
      link_text = 'content'
      render_inline(Pathogen::Link.new(href: url)) { link_text }
      assert_component_rendered
      assert_selector "a[href='#{url}']", text: link_text
      assert_selector "a[aria-label='#{I18n.t('pathogen.link.aria-label', content: link_text)}']"
    end

    # Integration tests for Link + Tooltip
    test 'renders link with tooltip using default top placement' do
      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: 'Helpful tooltip')
        'Link text'
      end

      # Verify link is wrapped in tooltip controller
      assert_selector 'div[data-controller="pathogen--tooltip"]'
      # Verify link has trigger target
      assert_selector 'a[data-pathogen--tooltip-target="trigger"]'
      # Verify tooltip exists with default top placement
      assert_selector 'div[role="tooltip"][data-placement="top"]', text: 'Helpful tooltip'
      # Verify aria-describedby connection
      assert_selector 'a[aria-describedby]'
    end

    test 'renders link with tooltip using custom bottom placement' do
      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: 'Helpful tooltip', placement: :bottom)
        'Link text'
      end

      # Verify tooltip has bottom placement
      assert_selector 'div[role="tooltip"][data-placement="bottom"]', text: 'Helpful tooltip'
      # Verify origin-top for bottom placement animation
      assert_selector 'span.origin-top'
    end

    test 'renders link with tooltip using left placement' do
      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: 'Helpful tooltip', placement: :left)
        'Link text'
      end

      # Verify tooltip has left placement
      assert_selector 'div[role="tooltip"][data-placement="left"]', text: 'Helpful tooltip'
      # Verify origin-right for left placement animation
      assert_selector 'span.origin-right'
    end

    test 'renders link with tooltip using right placement' do
      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: 'Helpful tooltip', placement: :right)
        'Link text'
      end

      # Verify tooltip has right placement
      assert_selector 'div[role="tooltip"][data-placement="right"]', text: 'Helpful tooltip'
      # Verify origin-left for right placement animation
      assert_selector 'span.origin-left'
    end

    test 'link with tooltip has proper aria-describedby connection' do
      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: 'Helpful tooltip')
        'Link text'
      end

      # Get the tooltip ID
      tooltip_element = page.find('div[role="tooltip"]')
      tooltip_id = tooltip_element[:id]

      # Verify link has aria-describedby pointing to tooltip
      assert_selector "a[aria-describedby='#{tooltip_id}']"
    end

    test 'link with tooltip has initial hidden state' do
      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: 'Helpful tooltip')
        'Link text'
      end

      # Verify tooltip starts hidden
      assert_selector 'div.opacity-0.scale-90.invisible'
    end

    test 'link without tooltip does not wrap in tooltip controller' do
      render_inline(Pathogen::Link.new(href: '/samples')) { 'Link text' }

      # Verify no tooltip controller
      assert_no_selector 'div[data-controller="pathogen--tooltip"]'
      # Verify no tooltip target
      assert_no_selector 'a[data-pathogen--tooltip-target="trigger"]'
      # Verify no tooltip element
      assert_no_selector 'div[role="tooltip"]'
    end

    test 'link with very long tooltip text respects max-width constraint' do
      long_text = 'This is a very long tooltip text that should be constrained by the max-w-xs class ' \
                  'to prevent the tooltip from becoming excessively wide and wrapping appropriately'

      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: long_text)
        'Link text'
      end

      # Verify tooltip has max-w-xs class for width constraint
      assert_selector 'div.max-w-xs', text: long_text
    end

    test 'link with tooltip maintains link styling and behavior' do
      render_inline(Pathogen::Link.new(href: '/samples')) do |link|
        link.with_tooltip(text: 'Helpful tooltip')
        'Link text'
      end

      # Verify link maintains standard styling
      assert_selector 'a.text-grey-900.dark\:text-grey-100.font-semibold.underline.hover\:decoration-2'
      # Verify href is preserved
      assert_selector "a[href='/samples']", text: 'Link text'
    end
  end
end
