# frozen_string_literal: true

require 'test_helper'

module Projects
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
    end

    test 'delete project with valid params' do
      assert_difference -> { Project.count } => -1, -> { Members::ProjectMember.count } => -1 do
        Projects::DestroyService.new(@project, @user).execute
      end
    end

    test 'delete project with invalid params' do
      user = users(:joan_doe)
      assert_no_difference ['Project.count', 'Members::ProjectMember.count'] do
        Projects::DestroyService.new(@project, user).execute
      end
    end
  end
end
