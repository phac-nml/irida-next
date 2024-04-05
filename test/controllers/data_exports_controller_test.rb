# frozen_string_literal: true

require 'test_helper'

class DataExportsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:john_doe)
    @sample1 = samples(:sample1)
    @data_export1 = data_exports(:data_export_one)
  end

  test 'should view exports' do
    get data_exports_path(@data_export1)
    assert_response :success
  end

  test 'should download export' do
    get download_data_export_path(@data_export1)
    assert_response :success
  end

  test 'should not download export without authorization' do
    sign_in users(:jane_doe)
    get download_data_export_path(@data_export1)
    assert_response :unauthorized
  end

  test 'should create new export with viable params' do
    params = { 'data_export' => { 'export_type' => 'sample', 'export_parameters' => { 'ids' => [@sample1.id] } },
               format: :turbo_stream }
    post data_exports_path(params)
    assert_response :redirect
  end

  test 'should delete export through destroy action' do
    assert_difference('DataExport.count', -1) do
      delete data_export_path(@data_export1),
             as: :turbo_stream
    end
    assert_response :success
  end

  test 'should delete export and redirect through destroy action if redirect param present' do
    assert_difference('DataExport.count', -1) do
      delete data_export_path(@data_export1, redirect: true),
             as: :turbo_stream
    end
    assert_response :redirect
  end

  test 'should not delete export without valid authorization' do
    sign_in users(:jane_doe)
    assert_no_difference('DataExport.count') do
      delete data_export_path(@data_export1),
             as: :turbo_stream
    end
    assert_response :unauthorized
  end

  test 'should view data export page' do
    get data_export_path(@data_export1)
    assert_response :success
  end

  test 'should not view data export page without proper authorization' do
    sign_in users(:jane_doe)
    get data_export_path(@data_export1)
    assert_response :unauthorized
  end

  test 'should redirect after clicking project link in preview tab' do
    get redirect_from_data_export_path(@data_export1, puid: 'INXT_PRJ_AAAAAAAAAA')
    assert_response :redirect
  end

  test 'should redirect after clicking sample link in preview tab' do
    get redirect_from_data_export_path(@data_export1, puid: 'INXT_SAM_AAAAAAAAAA')
    assert_response :redirect
  end
end
