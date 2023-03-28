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

      assert_changes -> { [@project.name, @project.path] } do
        Projects::UpdateService.new(@project, @user, valid_params).execute
      end
    end

    test 'update project with invalid params' do
      invalid_params = { namespace_attributes: { name: 'p1', path: 'p1' } }

      assert_no_difference ['Project.count', 'Members::ProjectMember.count'] do
        Projects::UpdateService.new(@project, @user, invalid_params).execute
      end
    end
  end
end
