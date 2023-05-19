# frozen_string_literal: true

require 'test_helper'

module Namespaces
  class UserNamespacePolicyTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
      @policy = Namespaces::UserNamespacePolicy.new(@project.namespace, user: @user)
    end

    test '#create?' do
      assert @policy.create?
    end

    test '#transfer_to_namespace?' do
      assert @policy.transfer_to_namespace?
    end

    test 'aliases' do
      assert_equal :create?, @policy.resolve_rule(:new?)
      assert_equal :create?, @policy.resolve_rule(:create?)
    end
  end
end
