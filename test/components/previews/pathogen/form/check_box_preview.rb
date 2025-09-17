# test/components/previews/pathogen/form/check_box_preview.rb
# frozen_string_literal: true

module Pathogen
  module Form
    # Preview for Pathogen::Form::CheckBox component
    #
    # This component renders checkbox inputs for Rails form builders with Pathogen styling.
    # It follows the exact Rails form.check_box helper signature and behavior.
    class CheckBoxPreview < ViewComponent::Preview
      include ActionView::Helpers::FormHelper
      include ActionView::Helpers::FormTagHelper
      include ActionView::Helpers::TagHelper
      include ActionView::Helpers::CaptureHelper

      layout 'pathogen_preview'

      # @!group Basic Form Examples

      # @label Default Form Checkbox
      # @param checked toggle "Checked state"
      def default(checked: false)
        render_form_example do |form|
          form.check_box(:newsletter, { checked: checked })
        end
      end

      # @label With Custom Values
      def with_custom_values
        render_form_example do |form|
          form.check_box(:subscription, {}, 'premium', 'basic')
        end
      end

      # @label Checked State
      def checked_state
        render_form_example do |form|
          form.check_box(:terms_accepted, { checked: true })
        end
      end

      # @!endgroup

      # @!group With HTML Options

      # @label With ID and Classes
      def with_id_and_classes
        render_form_example do |form|
          form.check_box(:marketing_emails, {
                           id: 'marketing-emails-checkbox',
                           class: 'custom-checkbox-class'
                         })
        end
      end

      # @label With ARIA Attributes
      def with_aria_attributes
        render_form_example do |form|
          form.check_box(:email_notifications, {
                           aria: {
                             label: 'Enable email notifications',
                             describedby: 'email-notifications-help'
                           }
                         })
        end
      end

      # @label With Data Attributes
      def with_data_attributes
        render_form_example do |form|
          form.check_box(:auto_save, {
                           data: {
                             action: 'input->autosave#toggle',
                             controller: 'autosave',
                             autosave_target: 'checkbox'
                           }
                         })
        end
      end

      # @label Disabled State
      def disabled_state
        render_form_example do |form|
          form.check_box(:readonly_field, {
                           disabled: true,
                           checked: true,
                           aria: { label: 'Read-only checkbox' }
                         })
        end
      end

      # @!endgroup

      # @!group Different Value Types

      # @label Boolean Field
      def boolean_field
        render_form_example(User.new(active: true)) do |form|
          form.check_box(:active)
        end
      end

      # @label String Values
      def string_values
        render_form_example do |form|
          form.check_box(:theme, {}, 'dark', 'light')
        end
      end

      # @label Numeric Values
      def numeric_values
        render_form_example do |form|
          form.check_box(:priority, {}, '1', '0')
        end
      end

      # @!endgroup

      # @!group Complex Form Scenarios

      # @label Multiple Checkboxes in Form
      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      def multiple_checkboxes_form
        render_form_example do |form|
          content_tag(:div, class: 'space-y-4') do
            safe_join([
                        content_tag(:fieldset, class: 'border border-gray-200 rounded p-4') do
                          safe_join([
                                      content_tag(:legend, 'Notification Preferences',
                                                  class: 'font-semibold text-sm px-2'),
                                      content_tag(:div, class: 'space-y-2 mt-2') do
                                        safe_join([
                                                    content_tag(:label, class: 'flex items-center space-x-2') do
                                                      safe_join([
                                                                  form.check_box(:email_notifications),
                                                                  content_tag(:span, 'Email notifications')
                                                                ])
                                                    end,
                                                    content_tag(:label, class: 'flex items-center space-x-2') do
                                                      safe_join([
                                                                  form.check_box(:sms_notifications),
                                                                  content_tag(:span, 'SMS notifications')
                                                                ])
                                                    end,
                                                    content_tag(:label, class: 'flex items-center space-x-2') do
                                                      safe_join([
                                                                  form.check_box(:push_notifications,
                                                                                 { checked: true }),
                                                                  content_tag(:span, 'Push notifications')
                                                                ])
                                                    end
                                                  ])
                                      end
                                    ])
                        end,
                        content_tag(:fieldset, class: 'border border-gray-200 rounded p-4') do
                          safe_join([
                                      content_tag(:legend, 'Privacy Settings', class: 'font-semibold text-sm px-2'),
                                      content_tag(:div, class: 'space-y-2 mt-2') do
                                        safe_join([
                                                    content_tag(:label, class: 'flex items-center space-x-2') do
                                                      safe_join([
                                                                  form.check_box(:public_profile),
                                                                  content_tag(:span, 'Public profile')
                                                                ])
                                                    end,
                                                    content_tag(:label, class: 'flex items-center space-x-2') do
                                                      safe_join([
                                                                  form.check_box(:allow_indexing, { checked: true }),
                                                                  content_tag(:span, 'Allow search engine indexing')
                                                                ])
                                                    end
                                                  ])
                                      end
                                    ])
                        end
                      ])
          end
        end
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

      # @label Nested Attributes
      # rubocop:disable Metrics/MethodLength
      def nested_attributes
        render_complex_form_example do |form|
          form.fields_for(:preferences) do |pref_form|
            content_tag(:div, class: 'space-y-3') do
              safe_join([
                          content_tag(:h4, 'User Preferences', class: 'font-medium'),
                          content_tag(:label, class: 'flex items-center space-x-2') do
                            safe_join([
                                        pref_form.check_box(:dark_mode),
                                        content_tag(:span, 'Enable dark mode')
                                      ])
                          end,
                          content_tag(:label, class: 'flex items-center space-x-2') do
                            safe_join([
                                        pref_form.check_box(:compact_view),
                                        content_tag(:span, 'Compact view')
                                      ])
                          end
                        ])
            end
          end
        end
      end
      # rubocop:enable Metrics/MethodLength

      # @!endgroup

      # @!group Without Hidden Field

      # @label Without Hidden Field
      def without_hidden_field
        render_form_example do |form|
          form.check_box(:optional_field, { include_hidden: false })
        end
      end

      # @!endgroup

      # @!group Error States

      # @label With Form Errors
      # rubocop:disable Metrics/MethodLength
      def with_form_errors
        user = User.new
        user.errors.add(:terms_accepted, 'must be accepted')

        render_form_example(user) do |form|
          content_tag(:div, class: 'space-y-2') do
            safe_join([
              content_tag(:label, class: 'flex items-center space-x-2') do
                safe_join([
                            form.check_box(:terms_accepted),
                            content_tag(:span, 'I accept the terms and conditions')
                          ])
              end,
              if user.errors[:terms_accepted].any?
                content_tag(:div, class: 'text-red-600 text-sm') do
                  user.errors[:terms_accepted].first
                end
              end
            ].compact)
          end
        end
      end
      # rubocop:enable Metrics/MethodLength

      # @!endgroup

      private

      def render_form_example(model = nil, &block)
        if model
          content_tag(:div, class: 'p-4 border border-gray-200 rounded-lg') do
            safe_join([
                        form_with(model: model, url: '#', local: true, class: 'space-y-4') do |form|
                          content_tag(:div, class: 'mb-4') do
                            capture(form, &block)
                          end
                        end,
                        content_tag(:div, class: 'mt-4 p-3 bg-gray-50 rounded text-sm') do
                          "#{content_tag(:strong, 'Note: ')}This checkbox uses Pathogen styling within a Rails form builder. It follows Rails naming conventions (object[method]) and includes hidden fields by default." # rubocop:disable Layout/LineLength
                        end
                      ])
          end
        else
          content_tag(:div, class: 'p-4 border border-gray-200 rounded-lg') do
            safe_join([
                        form_with(url: '#', local: true, class: 'space-y-4') do |form|
                          content_tag(:div, class: 'mb-4') do
                            capture(form, &block)
                          end
                        end,
                        content_tag(:div, class: 'mt-4 p-3 bg-gray-50 rounded text-sm') do
                          "#{content_tag(:strong, 'Note: ')}This demonstrates form_with integration with pathogen checkboxes." # rubocop:disable Layout/LineLength
                        end
                      ])
          end
        end
      end

      def render_complex_form_example(&block)
        content_tag(:div, class: 'p-4 border border-gray-200 rounded-lg') do
          safe_join([
                      form_with(url: '#', local: true, class: 'space-y-4') do |form|
                        content_tag(:div, class: 'mb-4') do
                          capture(form, &block)
                        end
                      end,
                      content_tag(:div, class: 'mt-4 p-3 bg-gray-50 rounded text-sm') do
                        "#{content_tag(:strong, 'Note: ')}This demonstrates complex form scenarios with nested attributes and multiple checkboxes." # rubocop:disable Layout/LineLength
                      end
                    ])
        end
      end

      def safe_join(array)
        array.compact.map(&:to_s).join.html_safe
      end

      # Simple User model for preview examples
      class User
        include ActiveModel::Model
        include ActiveModel::Attributes
        include ActiveModel::Validations

        attribute :id, :integer
        attribute :newsletter, :boolean, default: false
        attribute :subscription, :string, default: 'basic'
        attribute :terms_accepted, :boolean, default: false
        attribute :marketing_emails, :boolean, default: false
        attribute :email_notifications, :boolean, default: false
        attribute :auto_save, :boolean, default: true
        attribute :active, :boolean, default: false
        attribute :theme, :string, default: 'light'
        attribute :priority, :integer, default: 0
        attribute :sms_notifications, :boolean, default: false
        attribute :push_notifications, :boolean, default: true
        attribute :public_profile, :boolean, default: false
        attribute :allow_indexing, :boolean, default: true
        attribute :optional_field, :boolean, default: false

        def persisted?
          id.present?
        end

        def to_model
          self
        end

        def model_name
          @model_name ||= ActiveModel::Name.new(self.class, nil, 'User')
        end
      end
    end
  end
end
