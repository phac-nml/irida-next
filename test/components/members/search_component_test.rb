# frozen_string_literal: true

require 'test_helper'

module Members
  class SearchComponentTest < ViewComponent::TestCase
    test 'Should render a searchbox for a table of group members' do
      with_request_url '/-/groups/group-1/-/members' do
        q = Member.ransack
        tab = ''
        namespace = groups(:group_one)

        render_inline SearchComponent.new(q, tab, namespace)

        assert_selector "form[action='http://test.host/-/groups/group-1/-/members']", count: 1
        assert_selector "input[type='hidden'][name='tab'][value='#{tab}']", visible: false, count: 1
      end
    end

    test 'Should render a searchbox for a table of project members' do
      with_request_url '/group-1/project-1/-/members' do
        q = Member.ransack
        tab = 'invited_groups'
        project = projects(:project1)
        namespace = project.namespace

        render_inline SearchComponent.new(q, tab, namespace)

        assert_selector "form[action='http://test.host/group-1/project-1/-/members']", count: 1
        assert_selector "input[type='hidden'][name='tab'][value='#{tab}']", visible: false, count: 1
      end
    end
  end
end
