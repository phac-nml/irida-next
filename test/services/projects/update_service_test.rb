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

      assert_changes -> { [@project.name, @project.path] }, to: %w[new-project1-name new-project1-path] do
        Projects::UpdateService.new(@project, @user, valid_params).execute
      end
    end

    test 'update project with invalid params' do
      invalid_params = { namespace_attributes: { name: 'p1', path: 'p1' } }

      assert_no_difference ['Project.count', 'Member.count'] do
        Projects::UpdateService.new(@project, @user, invalid_params).execute
      end
    end

    test 'update project with incorrect permissions' do
      valid_params = { namespace_attributes: { name: 'new-project1-name', path: 'new-project1-path' } }
      user = users(:joan_doe)

      assert_no_changes -> { @project } do
        Projects::UpdateService.new(@project, user, valid_params).execute
      end
      assert @project.errors.full_messages.include?(I18n.t('services.projects.update.no_permission'))
    end
  end
end
