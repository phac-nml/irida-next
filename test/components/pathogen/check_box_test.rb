# frozen_string_literal: true

require 'test_helper'

module Pathogen
  module Form
    class CheckBoxTest < ViewComponent::TestCase
      # @!group Rails Form Builder Tests

      def test_renders_basic_checkbox_with_rails_form_pattern
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        user = MockObject.new(newsletter: false)
        form = ActionView::Helpers::FormBuilder.new('user', user, template, {})

        render_inline(CheckBox.new(:newsletter, {}, '1', '0', form: form))

        assert_selector "input[type='checkbox'][name='user[newsletter]'][value='1']"
        assert_selector "input[type='hidden'][name='user[newsletter]'][value='0']", visible: false
        assert_selector 'input#user_newsletter'

        # Should have Pathogen styling
        assert_selector 'input.size-6'
        assert_selector 'input.text-primary-600'
      end

      def test_renders_checkbox_with_custom_values
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        workflow = MockObject.new(active: false)
        form = ActionView::Helpers::FormBuilder.new('workflow', workflow, template, {})

        render_inline(CheckBox.new(:active, {}, 'yes', 'no', form: form))

        assert_selector "input[type='checkbox'][value='yes']"
        assert_selector "input[type='hidden'][value='no']", visible: false
        assert_selector "input[name='workflow[active]']"
      end

      def test_renders_checkbox_with_html_options
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        sample = MockObject.new(selected: false)
        form = ActionView::Helpers::FormBuilder.new('sample', sample, template, {})

        render_inline(CheckBox.new(:selected, {
                                     id: 'sample-selected',
                                     class: 'custom-class',
                                     data: { action: 'input->selection#toggle' }
                                   }, '1', '0', form: form))

        assert_selector 'input#sample-selected'
        assert_selector 'input.custom-class'
        assert_selector "input[data-action='input->selection#toggle']"

        # Custom classes should be merged with Pathogen classes
        assert_selector 'input.size-6.custom-class'
      end

      def test_renders_checked_checkbox
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        project = MockObject.new(public: true)
        form = ActionView::Helpers::FormBuilder.new('project', project, template, {})

        render_inline(CheckBox.new(:public, { checked: true }, '1', '0', form: form))

        assert_selector 'input[checked="checked"]'
      end

      def test_renders_disabled_checkbox
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        user = MockObject.new(admin: false)
        form = ActionView::Helpers::FormBuilder.new('user', user, template, {})

        render_inline(CheckBox.new(:admin, { disabled: true }, '1', '0', form: form))

        assert_selector 'input[disabled]'
      end

      def test_excludes_include_hidden_option_from_html_attributes
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        user = MockObject.new(active: false)
        form = ActionView::Helpers::FormBuilder.new('user', user, template, {})

        render_inline(CheckBox.new(:active, { include_hidden: false }, '1', '0', form: form))

        # Should not render hidden field
        assert_no_selector "input[type='hidden']"
        # Should not have include_hidden as HTML attribute
        assert_no_selector 'input[include_hidden]'
        assert_no_selector 'input[include-hidden]'
      end

      def test_handles_custom_classes
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        sample = MockObject.new(quality_control: false)
        form = ActionView::Helpers::FormBuilder.new('sample', sample, template, {})

        render_inline(CheckBox.new(:quality_control, { class: 'border-red-500 focus:ring-red-300' }, '1', '0',
                                   form: form))

        # Should have both Pathogen and custom classes
        assert_selector 'input.size-6.border-red-500'
        assert_selector 'input.text-primary-600.focus\\:ring-red-300'
      end

      def test_handles_class_as_array
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        workflow = MockObject.new(automated: false)
        form = ActionView::Helpers::FormBuilder.new('workflow', workflow, template, {})

        render_inline(CheckBox.new(:automated, { class: %w[custom-1 custom-2] }, '1', '0', form: form))

        assert_selector 'input.size-6'
        assert_selector 'input.custom-1'
        assert_selector 'input.custom-2'
      end

      def test_renders_with_aria_attributes
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        user = MockObject.new(consent: false)
        form = ActionView::Helpers::FormBuilder.new('user', user, template, {})

        render_inline(CheckBox.new(:consent, {
                                     'aria-label': 'Consent to data processing',
                                     'aria-describedby': 'consent-help'
                                   }, '1', '0', form: form))

        assert_selector "input[aria-label='Consent to data processing']"
        assert_selector "input[aria-describedby='consent-help']"
      end

      def test_renders_with_data_attributes
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        sample = MockObject.new(priority: false)
        form = ActionView::Helpers::FormBuilder.new('sample', sample, template, {})

        render_inline(CheckBox.new(:priority, {
                                     data: {
                                       controller: 'priority',
                                       action: 'change->priority#update',
                                       sample_type: 'genomic'
                                     }
                                   }, '1', '0', form: form))

        assert_selector "input[data-controller='priority']"
        assert_selector "input[data-action='change->priority#update']"
        assert_selector "input[data-sample-type='genomic']"
      end

      # @!endgroup

      # @!group Integration Tests

      def test_integration_with_biological_workflow_form
        template = ActionView::Base.new(ActionView::LookupContext.new([]), {}, nil)
        workflow = MockObject.new(
          generate_assembly: true,
          run_annotation: false,
          quality_control: true
        )
        form = ActionView::Helpers::FormBuilder.new('workflow', workflow, template, {})

        # Test assembly checkbox
        assembly_checkbox = CheckBox.new(:generate_assembly, {
                                           data: { step: 'assembly' }
                                         }, 'yes', 'no', form: form)

        render_inline(assembly_checkbox)
        assert_selector "input[name='workflow[generate_assembly]'][value='yes']"
        assert_selector "input[data-step='assembly']"
      end

      # @!endgroup

      private

      def page
        Capybara::Node::Simple.new(@rendered_content)
      end

      # Simple mock object class to replace deprecated OpenStruct
      class MockObject
        def initialize(**attributes)
          attributes.each do |key, value|
            define_singleton_method(key) { value }
          end
        end
      end
    end
  end
end
