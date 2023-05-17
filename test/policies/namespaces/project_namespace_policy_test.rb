# frozen_string_literal: true

require 'test_helper'

module Namespaces
  class ProjectNamespacePolicyTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
      @policy = Namespaces::ProjectNamespacePolicy.new(@project.namespace, user: @user)
    end

    test '#manage?' do
      assert @policy.manage?
    end

    test 'aliases' do
      assert_equal :manage?, @policy.resolve_rule(:new?)
      assert_equal :manage?, @policy.resolve_rule(:create?)
      assert_equal :manage?, @policy.resolve_rule(:update?)
    end
  end
end
