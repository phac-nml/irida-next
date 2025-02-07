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

    test 'should select samples' do
      timestamp = DateTime.current
      get select_group_samples_url(@group),
          params: { select: true, timestamp: timestamp },
          as: :turbo_stream
      assert_response :success
    end

    test 'should not select samples without permission' do
      sign_in users(:steve_doe)
      timestamp = DateTime.current
      get select_group_samples_url(@group),
          params: { select: true, timestamp: timestamp },
          as: :turbo_stream
      assert_response :unauthorized
    end

    test 'should handle metadata template none' do
      get group_samples_path(@group), params: { q: { metadata_template: 'none' } }
      assert_response :success
      doc = Nokogiri::HTML(response.body)
      assert doc.at_css('input[name="metadata_template"][value="none"]')
    end

    test 'should handle metadata template all' do
      get group_samples_path(@group), params: { q: { metadata_template: 'all' } }
      assert_response :success
      doc = Nokogiri::HTML(response.body)
      assert doc.at_css('input[name="metadata_template"][value="all"]')
    end

    test 'should handle specific metadata template' do
      template = metadata_templates(:valid_group_metadata_template)
      get group_samples_path(@group), params: { q: { metadata_template: template.id } }
      assert_response :success
      doc = Nokogiri::HTML(response.body)
      assert doc.at_css("input[name='metadata_template'][value='#{template.id}']")
    end

    test 'should not allow unauthorized access to index' do
      sign_in users(:steve_doe)
      get group_samples_path(@group)
      assert_response :unauthorized
    end

    test 'should store search params in session' do
      search_params = { name_or_puid_cont: 'test', sort: 'updated_at desc' }
      post search_group_samples_url(@group),
           params: { q: search_params },
           as: :turbo_stream
      assert_response :success
      assert_equal search_params.stringify_keys,
                   session["samples_#{@group.id}_search_params"].stringify_keys
    end
  end
end
