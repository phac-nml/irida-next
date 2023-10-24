# frozen_string_literal: true

require 'view_component_test_case'

module Viral
  class EmptyComponentTest < ViewComponentTestCase
    test 'default' do
      render_preview(:default)
      assert_selector 'span.Viral-Icon svg'
      assert_selector 'h3', text: I18n.t(:'groups.show.shared_projects.no_shared.title')
      assert_selector 'p', text: I18n.t(:'groups.show.shared_projects.no_shared.description')
    end
  end
end
