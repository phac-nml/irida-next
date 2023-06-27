# frozen_string_literal: true

require 'test_helper'

module Projects
  class TransferControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @project = projects(:project1)
      @namespace = namespaces_user_namespaces(:john_doe_namespace)
      @old_namespace = groups(:group_one)
    end

    test 'should transfer project' do
      post namespace_project_transfer_index_path(@old_namespace, @project),
           params: { new_namespace_id: @namespace.id }, as: :turbo_stream

      assert_response :redirect
    end

    test 'should not create a new transfer with wrong parameters' do
      post namespace_project_transfer_index_path(@old_namespace, @project),
           params: { new_namespace_id: 0 }, as: :turbo_stream

      assert_response :unprocessable_entity
    end

    test 'should not transfer a project to unowned namespace' do
      post namespace_project_transfer_index_path(@old_namespace, @project),
           params: { new_namespace_id: groups(:david_doe_group_four).id }

      assert_response :unauthorized
    end
  end
end
