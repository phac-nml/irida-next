# frozen_string_literal: true

require 'test_helper'

module Groups
  class HistoryControllerTest < ActionDispatch::IntegrationTest
    include Devise::Test::IntegrationHelpers

    test 'should get group history listing' do
      sign_in users(:john_doe)

      group = groups(:group_one)

      group.create_logidze_snapshot!

      get group_history_path(group)
      assert_response :success

      w3c_validate 'Group History Page'
    end

    test 'should display project history version' do
      sign_in users(:john_doe)

      group = groups(:group_one)

      group.create_logidze_snapshot!

      get group_view_history_path(group, version: 1, format: :turbo_stream)
      assert_response :success
    end
  end
end
