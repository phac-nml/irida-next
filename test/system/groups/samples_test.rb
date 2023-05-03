# frozen_string_literal: true

require 'application_system_test_case'

module Groups
  class SamplesTest < ApplicationSystemTestCase
    def setup
      login_as users(:john_doe)
      @group = groups(:group_one)
      @namespaces = Namespaces::ProjectNamespace.where(parent_id: @group.self_and_descendant_ids)
      @samples_count = samples.select { |sample| @namespaces.include?(sample.project.namespace) }.count
    end

    test 'visiting the index' do
      visit group_samples_url(@group)

      assert_selector 'h1', text: I18n.t(:'groups.samples.index.title')
      assert_selector 'tbody > tr', count: @samples_count
    end
  end
end
