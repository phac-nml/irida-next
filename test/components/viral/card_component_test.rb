# frozen_string_literal: true

require 'test_helper'

module Viral
  class CardComponentTest < ViewComponent::TestCase
    test 'default card' do
      render_inline(Viral::CardComponent.new(title: 'Simple card with Title')) do
        'This is a card'
      end

      assert_selector 'section.Viral-Card' do
        assert_selector 'h3.font-semibold' do
          assert_text 'Simple card with Title'
        end
        assert_text 'This is a card'
      end
    end

    test 'card with header actions' do
      render_inline(Viral::CardComponent.new(title: 'Card with header actions')) do |card|
        card.header(title: 'This is a card with header actions') do |header|
          header.action do
            'Edit'
          end
          header.action do
            'Delete'
          end
          'Just the body here'
        end
      end

      assert_selector 'section.Viral-Card' do
        assert_text 'This is a card with header actions'
        assert_text 'Edit'
        assert_text 'Delete'
        assert_text 'Just the body here'
      end
    end

    test 'card with simple header' do
      render_inline(Viral::CardComponent.new) do |card|
        card.header(title: 'This is a card with a simple header')
      end

      assert_selector 'section.Viral-Card' do
        assert_text 'This is a card with a simple header'
      end
    end

    test 'card with multiple sections' do
      render_inline(Viral::CardComponent.new(title: 'Card with multiple sections')) do |card|
        card.header(title: 'This is a card with multiple sections')
        card.section { 'This is section 1 content' }
        card.section(border_top: true) { 'This is section 2 content' }
      end

      assert_selector 'section.Viral-Card' do
        assert_text 'This is a card with multiple sections'
        assert_selector '.Viral-Card--Section', count: 2
        assert_text 'This is section 1 content'
        assert_text 'This is section 2 content'
      end
    end

    test 'card with titled sections' do
      render_inline(Viral::CardComponent.new(title: 'Card with titled sections')) do |card|
        card.header(title: 'This is a card with multiple titled sections')
        card.section(title: 'Section 1') { 'This is section 1 content' }
        card.section(title: 'Section 2', border_top: true) { 'This is section 2 content' }
      end

      assert_selector 'section.Viral-Card' do
        assert_selector '.Viral-Card--Section', count: 2
        assert_text 'SECTION 1'
        assert_text 'This is section 1 content'
        assert_text 'SECTION 2'
        assert_text 'This is section 2 content'
      end
    end

    test 'card section with action' do
      render_inline(Viral::CardComponent.new(title: 'Card section with action')) do |card|
        card.header(title: 'This is a card with a section with an action')
        card.section(title: 'Section 1') do |section|
          section.action do
            'Edit'
          end
        end
      end

      assert_selector 'section.Viral-Card' do
        assert_selector '.Viral-Card--Section', count: 1
        assert_text 'SECTION 1'
        assert_text 'Edit'
      end
    end
  end
end
