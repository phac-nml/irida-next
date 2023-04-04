# frozen_string_literal: true

require 'test_helper'

module Projects
  class CreateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @parent_namespace = namespaces_user_namespaces(:john_doe_namespace)
      @parent_group_namespace = groups(:group_one)
    end

    test 'create project with valid params under user namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_namespace.id } }

      assert_difference -> { Project.count } => 1, -> { Members::ProjectMember.count } => 1 do
        Projects::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create project with invalid params' do
      invalid_params = { namespace_attributes: { name: 'proj1', path: 'proj1' } }

      assert_no_difference ['Project.count', 'Members::ProjectMember.count'] do
        Projects::CreateService.new(@user, invalid_params).execute
      end
    end

    test 'create project with valid params but incorrect permissions under user namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_namespace.id } }
      user = users(:steve_doe)
      assert_no_difference ['Project.count', 'Members::ProjectMember.count'] do
        Projects::CreateService.new(user, valid_params).execute
      end
    end

    test 'create project with valid params under group namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_group_namespace.id } }

      assert_difference -> { Project.count } => 1, -> { Members::ProjectMember.count } => 1 do
        Projects::CreateService.new(@user, valid_params).execute
      end
    end

    test 'create project with valid params but incorrect permissions under group namespace' do
      valid_params = { namespace_attributes: { name: 'proj1', path: 'proj1', parent_id: @parent_group_namespace.id } }
      user = users(:steve_doe)
      assert_no_difference ['Project.count', 'Members::ProjectMember.count'] do
        Projects::CreateService.new(user, valid_params).execute
      end
    end
  end
end
