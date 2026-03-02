# frozen_string_literal: true

require 'test_helper'

module GlobalSearch
  class FrequentItemsTest < ActiveSupport::TestCase
    setup do
      @user = users(:john_doe)
      @project_namespace = namespaces_project_namespaces(:project1_namespace)
      @group = groups(:group_one)
    end

    test 'returns recent projects and groups from user-owned namespace activities' do
      PublicActivity::Activity.create!(
        owner: @user,
        trackable: @project_namespace,
        key: 'namespaces_project_namespace.update',
        parameters: {},
        created_at: 10.minutes.ago,
        updated_at: 10.minutes.ago
      )
      PublicActivity::Activity.create!(
        owner: @user,
        trackable: @group,
        key: 'group.update',
        parameters: {},
        created_at: 5.minutes.ago,
        updated_at: 5.minutes.ago
      )

      results = GlobalSearch::FrequentItems.new(@user, limit: 5).call

      assert_includes results[:projects].pluck(:title), 'Project 1'
      assert_includes results[:groups].pluck(:title), @group.name
    end

    test 'ignores namespace activities not owned by current user' do
      PublicActivity::Activity.create!(
        owner: users(:jane_doe),
        trackable: @project_namespace,
        key: 'namespaces_project_namespace.update',
        parameters: {}
      )

      results = GlobalSearch::FrequentItems.new(@user, limit: 5).call

      assert_equal [], results[:projects]
      assert_equal [], results[:groups]
    end
  end
end
