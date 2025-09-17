# test/components/previews/pathogen/form/check_box_tag_preview.rb
# frozen_string_literal: true

module Pathogen
  module Form
    # Preview for Pathogen::Form::CheckBoxTag component
    #
    # This component renders standalone checkbox inputs with Pathogen styling.
    # It follows the exact Rails check_box_tag helper signature and behavior.
    class CheckBoxTagPreview < ViewComponent::Preview
      include ActionView::Helpers::FormHelper
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::CaptureHelper

      layout 'pathogen_preview'

      # @!group Basic Examples

      # @label Default Checkbox
      # @param name text "Field name"
      # @param value text "Field value"
      # @param checked toggle "Checked state"
      def default(name: 'newsletter', value: '1', checked: false)
        render_checkbox_example do
          check_box_tag(name, value, checked)
        end
      end

      # @label With Custom Value
      def with_custom_value
        render_checkbox_example do
          check_box_tag('subscription', 'premium', false)
        end
      end

      # @label Checked State
      def checked_state
        render_checkbox_example do
          check_box_tag('terms', 'accepted', true)
        end
      end

      # @!endgroup

      # @!group With Options

      # @label With ID and Classes
      def with_id_and_classes
        render_checkbox_example do
          check_box_tag('marketing', '1', false, {
                          id: 'marketing-checkbox',
                          class: 'my-checkbox additional-class'
                        })
        end
      end

      # @label With ARIA Labels
      def with_aria_labels
        render_checkbox_example do
          check_box_tag('notifications', '1', false, {
                          id: 'notifications',
                          aria: {
                            label: 'Enable email notifications',
                            describedby: 'notifications-help'
                          }
                        })
        end
      end

      # @label With Data Attributes
      def with_data_attributes
        render_checkbox_example do
          check_box_tag('sample_ids[]', '123', false, {
                          id: 'sample-123',
                          data: {
                            action: 'input->selection#toggle',
                            selection_target: 'rowSelection',
                            value: 'Sample 123'
                          }
                        })
        end
      end

      # @label Disabled State
      def disabled_state
        render_checkbox_example do
          check_box_tag('readonly', '1', false, {
                          disabled: true,
                          aria: { label: 'Read-only field' }
                        })
        end
      end

      # @!endgroup

      # @!group Array Fields

      # @label Multiple Checkboxes (Array Pattern)
      def multiple_checkboxes_array
        render_checkbox_example do
          content_tag(:div, class: 'space-y-2') do
            safe_join([
                        content_tag(:label, class: 'flex items-center space-x-2') do
                          safe_join([
                                      check_box_tag('sample_ids[]', '1', false, {
                                                      id: 'sample-1',
                                                      aria: { label: 'Sample 1' }
                                                    }),
                                      content_tag(:span, 'Sample 1')
                                    ])
                        end,
                        content_tag(:label, class: 'flex items-center space-x-2') do
                          safe_join([
                                      check_box_tag('sample_ids[]', '2', true, {
                                                      id: 'sample-2',
                                                      aria: { label: 'Sample 2' }
                                                    }),
                                      content_tag(:span, 'Sample 2')
                                    ])
                        end,
                        content_tag(:label, class: 'flex items-center space-x-2') do
                          safe_join([
                                      check_box_tag('sample_ids[]', '3', false, {
                                                      id: 'sample-3',
                                                      aria: { label: 'Sample 3' }
                                                    }),
                                      content_tag(:span, 'Sample 3')
                                    ])
                        end
                      ])
          end
        end
      end

      # @label Select All Pattern
      def select_all_pattern
        render_checkbox_example do
          content_tag(:div, class: 'space-y-3') do
            safe_join([
                        content_tag(:div, class: 'border-b pb-2') do
                          content_tag(:label, class: 'flex items-center space-x-2 font-semibold') do
                            safe_join([
                                        check_box_tag('select-all', '1', false, {
                                                        id: 'select-all',
                                                        aria: { label: 'Select all items' },
                                                        data: { action: 'input->selection#toggleAll' }
                                                      }),
                                        content_tag(:span, 'Select All')
                                      ])
                          end
                        end,
                        content_tag(:div, class: 'space-y-2 ml-4') do
                          safe_join([
                                      content_tag(:label, class: 'flex items-center space-x-2') do
                                        safe_join([
                                                    check_box_tag('item_ids[]', 'item1', false, {
                                                                    id: 'item-1',
                                                                    aria: { label: 'Item 1' },
                                                                    data: { action: 'input->selection#toggle' }
                                                                  }),
                                                    content_tag(:span, 'Item 1')
                                                  ])
                                      end,
                                      content_tag(:label, class: 'flex items-center space-x-2') do
                                        safe_join([
                                                    check_box_tag('item_ids[]', 'item2', false, {
                                                                    id: 'item-2',
                                                                    aria: { label: 'Item 2' },
                                                                    data: { action: 'input->selection#toggle' }
                                                                  }),
                                                    content_tag(:span, 'Item 2')
                                                  ])
                                      end,
                                      content_tag(:label, class: 'flex items-center space-x-2') do
                                        safe_join([
                                                    check_box_tag('item_ids[]', 'item3', false, {
                                                                    id: 'item-3',
                                                                    aria: { label: 'Item 3' },
                                                                    data: { action: 'input->selection#toggle' }
                                                                  }),
                                                    content_tag(:span, 'Item 3')
                                                  ])
                                      end
                                    ])
                        end
                      ])
          end
        end
      end

      # @!endgroup

      # @!group Real-World Examples

      # @label Workflow Step Selection
      def workflow_step_selection
        render template: 'pathogen/form/check_box_tag_preview/workflow_step_selection'
      end

      # @!endgroup

      # @!group Without Hidden Field

      # @label Without Hidden Field
      def without_hidden_field
        render_checkbox_example do
          check_box_tag('no_hidden', '1', false, {
                          include_hidden: false,
                          id: 'no-hidden-field'
                        })
        end
      end

      # @!endgroup

      # @!group Edge Cases

      # @label Empty String Value
      def empty_string_value
        render_checkbox_example do
          check_box_tag('empty_value', '', false, {
                          id: 'empty-value'
                        })
        end
      end

      # @label Special Characters in Name
      def special_characters_name
        render_checkbox_example do
          check_box_tag('user[settings][email_notifications]', '1', false, {
                          id: 'user_settings_email_notifications'
                        })
        end
      end

      # @label Long Value
      def long_value
        render_checkbox_example do
          check_box_tag('metadata', 'very-long-metadata-value-that-might-be-used-in-real-applications', false, {
                          id: 'metadata-checkbox'
                        })
        end
      end

      # @!endgroup

      private

      def render_checkbox_example(&block)
        content_tag(:div, class: 'p-4 border border-gray-200 rounded-lg') do
          safe_join([
                      content_tag(:div, class: 'mb-4') do
                        capture(&block)
                      end,
                      content_tag(:div, class: 'mt-4 p-3 bg-gray-50 rounded text-sm') do
                        content_tag(:strong, 'Note: ') +
                        'This checkbox uses Pathogen styling and follows Rails check_box_tag conventions. ' +
                        'It includes a hidden field by default for proper form submission.'
                      end
                    ])
        end
      end

      def safe_join(array)
        array.map(&:to_s).join.html_safe
      end
    end
  end
end
