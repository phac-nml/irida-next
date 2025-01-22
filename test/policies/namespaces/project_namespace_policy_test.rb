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
      assert @policy.apply(:update?)
    end

    test '#create_member?' do
      assert @policy.apply(:create_member?)
    end

    test '#update_member?' do
      assert @policy.apply(:update_member?)
    end

    test '#destroy_member?' do
      assert @policy.apply(:destroy_member?)
    end

    test '#member_listing?' do
      assert @policy.apply(:member_listing?)
    end

    test '#link_namespace_with_group?' do
      assert @policy.apply(:link_namespace_with_group?)
    end

    test '#unlink_namespace_with_group?' do
      assert @policy.apply(:unlink_namespace_with_group?)
    end

    test '#update_namespace_with_group_link?' do
      assert @policy.apply(:update_namespace_with_group_link?)
    end

    test '#create_automated_workflow_executions?' do
      assert @policy.apply(:create_automated_workflow_executions?)
    end

    test '#destroy_automated_workflow_executions?' do
      assert @policy.apply(:destroy_automated_workflow_executions?)
    end

    test '#update_automated_workflow_executions?' do
      assert @policy.apply(:update_automated_workflow_executions?)
    end

    test '#view_automated_workflow_executions?' do
      assert @policy.apply(:view_automated_workflow_executions?)
    end

    test '#view_workflow_executions?' do
      assert @policy.apply(:view_automated_workflow_executions?)
    end

    test '#update_sample_metadata?' do
      assert @policy.apply(:update_sample_metadata?)
    end

    test '#create_metadata_template?' do
      assert @policy.apply(:create_metadata_template?)
    end

    test '#update_metadata_template?' do
      assert @policy.apply(:update_metadata_template?)
    end

    test '#destroy_metadata_template?' do
      assert @policy.apply(:destroy_metadata_template?)
    end

    test '#view_metadata_templates?' do
      assert @policy.apply(:view_metadata_templates?)
    end
  end
end
