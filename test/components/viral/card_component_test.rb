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
            content_tag('a', 'Edit',
                        class: 'font-medium text-blue-600 dark:text-blue-500 hover:underline cursor-pointer')
          end
          header.action do
            content_tag('a', 'Delete',
                        class: 'font-medium text-red-600 dark:text-red-500 hover:underline cursor-pointer')
          end
          'Just the body here'
        end
      end

      assert_selector 'section.Viral-Card' do
        assert_selector 'h3.font-semibold' do
          assert_text 'Card with header actions'
        end
        assert_selector 'div.p-4.pb-0' do
          assert_selector 'a.font-medium.text-blue-600.dark:text-blue-500.hover:underline.cursor-pointer' do
            assert_text 'Edit'
          end
          assert_selector 'a.font-medium.text-red-600.dark:text-red-500.hover:underline.cursor-pointer' do
            assert_text 'Delete'
          end
        end
        assert_text 'Just the body here'
      end
    end
  end
end
