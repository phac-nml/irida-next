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

    test 'render arbitrary class names' do
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
  end
end
