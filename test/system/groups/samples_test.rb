# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class SamplesTest < ApplicationSystemTestCase
    def setup
      login_as users(:john_doe)
      @group = groups(:group_one)
    end

    test 'visiting the index' do
      visit group_samples_url(@group)

      assert_selector 'h1', text: I18n.t(:'groups.samples.index.title')
      assert_selector 'tbody > tr', count: 20
      assert_text samples(:sample3).name
      assert_selector 'a', text: I18n.t(:'components.pagination.next')
      assert_no_selector 'a', text: I18n.t(:'components.pagination.previous')

      click_on I18n.t(:'components.pagination.next')
      assert_selector 'tbody > tr', count: 2
      click_on I18n.t(:'components.pagination.previous')
      assert_selector 'tbody > tr', count: 20

      click_link samples(:sample3).name
      assert_selector 'h1', text: samples(:sample3).name
    end

    test 'cannot access group samples' do
      login_as users(:david_doe)

      visit group_samples_url(@group)

      assert_text I18n.t(:'action_policy.policy.group.sample_listing?', name: @group.name)
    end
  end
end
