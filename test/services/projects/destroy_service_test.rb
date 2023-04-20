# frozen_string_literal: true

require 'test_helper'

module Projects
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
    end

    test 'delete project with with correct permissions' do
      assert_difference -> { Project.count } => -1, -> { Member.count } => -3 do
        Projects::DestroyService.new(@project, @user).execute
      end
    end

    test 'delete project with incorrect permissions' do
      user = users(:joan_doe)
      assert_no_difference ['Project.count', 'Member.count'] do
        Projects::DestroyService.new(@project, user).execute
      end
      assert @project.errors.full_messages.include?(I18n.t('services.projects.destroy.no_permission'))
    end
  end
end
