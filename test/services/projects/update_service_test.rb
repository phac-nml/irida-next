# frozen_string_literal: true

require 'test_helper'

module Projects
  class UpdateServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:project1)
    end

    test 'update project with valid params' do
      valid_params = { namespace_attributes: { name: 'new-project1-name', path: 'new-project1-path' } }

      Projects::UpdateService.new(@project, @user, valid_params).execute

      assert_equal 'new-project1-name', @project.reload.name
      assert_equal 'new-project1-path', @project.reload.path
    end

    test 'cupdate project with invalid params' do
      invalid_params = { namespace_attributes: { name: 'p1', path: 'p1' } }

      Projects::UpdateService.new(@project, @user, invalid_params).execute

      assert_not_equal 'p1', @project.reload.name
      assert_not_equal 'p1', @project.reload.path
    end
  end
end
