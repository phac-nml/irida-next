# frozen_string_literal: true

require 'application_system_test_case'

module Viral
  module Form
    module Prefixed
      class Select2ComponentTest < ApplicationSystemTestCase
        test 'default' do
          visit '/rails/view_components/viral_form_prefixed_select2_component/default'
          assert_selector 'input[type="hidden"][name="user"]', visible: :hidden, count: 1

          find('input.select2-input[type="text"]').click
          assert_selector 'div[data-viral--select2-target="dropdown"]', visible: :visible
          assert_selector 'ul[data-viral--select2-target="scroller"] li', count: 50

          find('li[data-label="User 1"]').click
          assert_selector 'input[type="hidden"][name="user"][value="1"]', visible: :hidden, count: 1

          find('input.select2-input[type="text"]').send_keys([:ctrl, 'a'], '22')
          assert_selector 'div[data-viral--select2-target="dropdown"]', visible: :visible
          find('ul[data-viral--select2-target="scroller"] > li').click

          assert_selector 'input[type="hidden"][name="user"][value="22"]', visible: :hidden, count: 1
        end
      end
    end
  end
end
