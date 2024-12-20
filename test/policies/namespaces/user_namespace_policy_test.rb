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
      assert @policy.apply(:create?)
    end

    test '#transfer_into_namespace?' do
      assert @policy.apply(:transfer_into_namespace?)
    end
  end
end
