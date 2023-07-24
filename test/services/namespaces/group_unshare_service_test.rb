# frozen_string_literal: true

require 'test_helper'

module Namespaces
  class GroupUnshareServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
    end

    test 'unshare group b with group a' do
      group = groups(:group_three)
      namespace = groups(:subgroup1)

      assert_difference -> { NamespaceGroupLink.count } => -1 do
        Namespaces::GroupUnshareService.new(@user, group.id, namespace).execute
      end
    end

    test 'share group b with group a then unshare' do
      group = groups(:group_one)
      namespace = groups(:group_six)

      assert_difference -> { NamespaceGroupLink.count } => 1 do
        Namespaces::GroupShareService.new(@user, group.id, namespace, Member::AccessLevel::ANALYST).execute
      end

      assert_difference -> { NamespaceGroupLink.count } => -1 do
        Namespaces::GroupUnshareService.new(@user, group.id, namespace).execute
      end
    end
  end
end
