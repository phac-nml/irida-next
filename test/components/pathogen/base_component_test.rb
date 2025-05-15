# frozen_string_literal: true

require 'test_helper'

module Pathogen
  class BaseComponentTest < ViewComponent::TestCase
    test 'renders data view component' do
      render_inline Pathogen::BaseComponent.new(tag: :div)

      assert_selector 'div[data-view-component]'
    end

    test 'renders title' do
      render_inline Pathogen::BaseComponent.new(tag: :div, title: 'title')

      assert_selector 'div[title="title"]'
    end

    test 'renders content' do
      render_inline Pathogen::BaseComponent.new(tag: :div) do
        'content'
      end

      assert_text 'content'
    end

    test 'renders empty content for self-closing tags' do
      render_inline Pathogen::BaseComponent.new(tag: :input)

      # Should not raise an error about content being passed to self-closing tag
      assert_selector 'input[type="text"]', count: 0
      assert_selector 'input[type="text"]:not([value])', count: 0
    end

    test 'renders self-closing tags properly' do
      render_inline Pathogen::BaseComponent.new(tag: :img, src: 'test.jpg', alt: 'Test')
      
      # Check that it's rendered as a self-closing tag
      assert_selector 'img[src="test.jpg"][alt="Test"]', count: 1
    end

    test 'renders style attribute' do
      render_inline Pathogen::BaseComponent.new(
        tag: :div, 
        style: 'color: red; font-size: 16px;'
      )

      assert_selector 'div[style*="color: red"][style*="font-size: 16px"]'
    end

    test 'merges class names' do
      render_inline Pathogen::BaseComponent.new(
        tag: :div, 
        classes: 'foo bar',
        class: 'baz qux'
      )

      assert_selector 'div.foo.bar.baz.qux'
    end

    test 'renders arbitrary class names' do
      render_inline Pathogen::BaseComponent.new(tag: :div, classes: 'foo bar')

      assert_selector 'div.foo.bar'
    end

    test 'renders as a link' do
      render_inline Pathogen::BaseComponent.new(tag: :a, href: 'https://example.com')

      assert_selector 'a[href="https://example.com"]'
    end

    test 'renders data attribute' do
      render_inline Pathogen::BaseComponent.new(tag: :div, 'data-foo': 'bar')

      assert_selector 'div[data-foo="bar"]'
    end

    test 'adds test selector' do
      render_inline Pathogen::BaseComponent.new(tag: :div, test_selector: 'test-component')
      
      assert_selector 'div[data-test-selector="test-component"]'
    end

    test 'handles multiple data attributes' do
      render_inline Pathogen::BaseComponent.new(
        tag: :div, 
        'data-controller': 'controller',
        'data-action': 'action',
        'data-test-id': 'test-id'
      )
      
      assert_selector 'div[data-controller="controller"]'\
                     '[data-action="action"]'\
                     '[data-test-id="test-id"]'
    end
  end
end
