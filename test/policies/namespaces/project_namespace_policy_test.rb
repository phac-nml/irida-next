# frozen_string_literal: true

require 'test_helper'

module Namespaces
  class ProjectNamespacePolicyTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
      @policy = Namespaces::ProjectNamespacePolicy.new(@project.namespace, user: @user)
    end

    test '#allowed_to_modify_project_namespace?' do
      assert @policy.allowed_to_modify_project_namespace?
    end

    test '#allowed_to_view_project_namespace?' do
      assert @policy.allowed_to_view_project_namespace?
    end

    test '#allowed_to_destroy?' do
      assert @policy.allowed_to_destroy?
    end

    test 'aliases' do
      assert_equal :allowed_to_modify_project_namespace?, @policy.resolve_rule(:new?)
      assert_equal :allowed_to_modify_project_namespace?, @policy.resolve_rule(:create?)
      assert_equal :allowed_to_modify_project_namespace?, @policy.resolve_rule(:update?)

      assert_equal :allowed_to_view_project_namespace?, @policy.resolve_rule(:index?)

      assert_equal :allowed_to_destroy?, @policy.resolve_rule(:destroy?)
    end
  end
end
