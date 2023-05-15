# frozen_string_literal: true

require 'test_helper'

module Namespaces
  class UserNamespacePolicyTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
      @policy = Namespaces::UserNamespacePolicy.new(@project.namespace, user: @user)
    end

    test '#allowed_to_modify_projects_under_namespace?' do
      assert @policy.allowed_to_modify_projects_under_namespace?
    end

    test '#allowed_to_destroy?' do
      assert @policy.allowed_to_destroy?
    end

    test '#transfer_to_namespace?' do
      assert @policy.transfer_to_namespace?
    end

    test 'aliases' do
      assert_equal :allowed_to_modify_projects_under_namespace?, @policy.resolve_rule(:new?)
      assert_equal :allowed_to_modify_projects_under_namespace?, @policy.resolve_rule(:create?)

      assert_equal :allowed_to_destroy?, @policy.resolve_rule(:destroy?)
    end
  end
end
