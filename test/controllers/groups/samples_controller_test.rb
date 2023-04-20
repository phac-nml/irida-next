# frozen_string_literal: true

require 'test_helper'

module Groups
  class SamplesControllerTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:john_doe)
      @group = groups(:group_one)
    end

    test 'should get index' do
      get group_samples_path(@group)
      assert_response :success
    end
  end
end
