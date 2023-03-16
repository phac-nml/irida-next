# frozen_string_literal: true

require 'test_helper'

class SamplesControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:john_doe)
    @sample = samples(:one)
  end

  test 'should get index' do
    get samples_url
    assert_response :success
  end

  test 'should get new' do
    get new_sample_url
    assert_response :success
  end

  test 'should create sample' do
    assert_difference('Sample.count') do
      post samples_url,
           params: { sample: { description: @sample.description, name: @sample.name,
                               project_id: @sample.project_id } }
    end

    assert_redirected_to sample_url(Sample.last)
  end

  test 'should show sample' do
    get sample_url(@sample)
    assert_response :success
  end

  test 'should get edit' do
    get edit_sample_url(@sample)
    assert_response :success
  end

  test 'should update sample' do
    patch sample_url(@sample),
          params: { sample: { description: @sample.description, name: @sample.name, project_id: @sample.project_id } }
    assert_redirected_to sample_url(@sample)
  end

  test 'should destroy sample' do
    assert_difference('Sample.count', -1) do
      delete sample_url(@sample)
    end

    assert_redirected_to samples_url
  end
end
