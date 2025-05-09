# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class EmptyComponentTest < ViewComponentTestCase
    test 'default' do
      render_preview(:default)
      assert_selector 'span.viral-icon svg'
      assert_selector 'h2', text: I18n.t(:'groups.show.shared_namespaces.no_shared.title')
      assert_selector 'span', text: I18n.t(:'groups.show.shared_namespaces.no_shared.description')
    end
  end
end
