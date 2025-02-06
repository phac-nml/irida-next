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

    test 'should search' do
      post search_group_samples_url(@group),
           params: { q: { name_or_puid_cont: '',
                          groups_attributes: { '0': { conditions_attributes:
                          { '0': { field: 'name', operator: 'contains', value: 'Sample 1' } } } } } },
           as: :turbo_stream
      assert_response :success
    end

    test 'should not search with invalid query' do
      post search_group_samples_url(@group),
           params: { q: { name_or_puid_cont: '',
                          groups_attributes: { '0': { conditions_attributes:
                          { '0': { field: 'name', operator: 'contains', value: '' } } } } } },
           as: :turbo_stream
      assert_response :unprocessable_entity
    end
  end
end
