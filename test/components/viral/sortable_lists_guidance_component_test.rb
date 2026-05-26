# frozen_string_literal: true

require 'test_helper'

module Viral
  class SortableListsGuidanceComponentTest < ViewComponent::TestCase
    test 'renders stable description ids for list aria-describedby references' do
      render_inline(
        Viral::SortableListsGuidanceComponent.new(
          title: 'How the lists work',
          instructions: 'Move fields between lists.',
          keyboard_help: 'Keyboard shortcuts are available.',
          id_prefix: 'metadata-guidance',
          available: {
            title: 'Not imported',
            description: 'Fields that will not be imported.'
          },
          selected: {
            title: 'Will be imported',
            description: 'Fields that will be imported.'
          }
        )
      )

      assert_selector '#metadata-guidance-available-description', text: 'Not imported'
      assert_selector '#metadata-guidance-available-description', text: 'Fields that will not be imported.'
      assert_selector '#metadata-guidance-selected-description', text: 'Will be imported'
      assert_selector '#metadata-guidance-selected-description', text: 'Fields that will be imported.'
    end

    test 'generates valid description ids when no id_prefix is provided' do
      component = Viral::SortableListsGuidanceComponent.new(
        title: 'How the lists work',
        instructions: 'Move fields between lists.',
        keyboard_help: 'Keyboard shortcuts are available.',
        available: { title: 'Not imported', description: 'Fields that will not be imported.' },
        selected: { title: 'Will be imported', description: 'Fields that will be imported.' }
      )

      assert_match(/\Asortable-lists-guidance-[0-9a-f]{8}-available-description\z/, component.available_description_id)
      assert_match(/\Asortable-lists-guidance-[0-9a-f]{8}-selected-description\z/, component.selected_description_id)

      render_inline(component)

      assert_selector "[id='#{component.available_description_id}']", text: 'Not imported'
      assert_selector "[id='#{component.selected_description_id}']", text: 'Will be imported'
    end
  end
end
