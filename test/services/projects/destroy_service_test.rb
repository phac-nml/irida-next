# frozen_string_literal: true

require 'test_helper'

module Projects
  class DestroyServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @project = projects(:john_doe_project2)
    end

    test 'delete project with with correct permissions' do
      assert_difference -> { Project.count } => -1, -> { Member.count } => -4 do
        Projects::DestroyService.new(@project, @user).execute
      end
    end

    test 'delete project with incorrect permissions' do
      user = users(:joan_doe)

      assert_raises(ActionPolicy::Unauthorized) { Projects::DestroyService.new(@project, user).execute }
    end
  end
end
