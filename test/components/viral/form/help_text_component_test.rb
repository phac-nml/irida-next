# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  module Form
    class HelpTextComponentTest < ViewComponentTestCase
      def test_default
        render_preview(:default)

        assert_selector 'span.text-slate-500', text: 'Default help text!'
      end

      def test_success
        render_preview(:success)

        assert_selector 'span.text-green-600', text: 'Success help text!'
      end

      def test_error
        render_preview(:error)

        assert_selector 'span.text-red-600', text: 'Error help text!'
      end
    end
  end
end
