# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class SamplesTest < ApplicationSystemTestCase
    def setup
      login_as users(:john_doe)
      @group = groups(:group_one)
      @samples_count = samples.select { |sample| @group.descendants.include?(sample.project.namespace) }.count
    end

    test 'visiting the index' do
      visit group_samples_url(@group)

      assert_selector 'h1', text: I18n.t(:'groups.samples.index.title')
      assert_selector 'tbody > tr', count: @samples_count
    end
  end
end
