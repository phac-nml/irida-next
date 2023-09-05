# frozen_string_literal: true

require 'test_helper'

module Namespaces
  class ProjectNamespacePolicyTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
      @policy = Namespaces::ProjectNamespacePolicy.new(@project.namespace, user: @user)
    end

    test '#update?' do
      assert @policy.update?
    end

    test '#create_member?' do
      assert @policy.create_member?
    end

    test '#update_member?' do
      assert @policy.update_member?
    end

    test '#destroy_member?' do
      assert @policy.destroy_member?
    end

    test '#member_listing?' do
      assert @policy.member_listing?
    end

    test '#link_namespace_with_group?' do
      assert @policy.link_namespace_with_group?
    end

    test '#unlink_namespace_with_group?' do
      assert @policy.unlink_namespace_with_group?
    end

    test '#update_namespace_with_group_link?' do
      assert @policy.update_namespace_with_group_link?
    end
  end
end
