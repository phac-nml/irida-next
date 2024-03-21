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

  test 'should delete export' do
    assert_difference('DataExport.count', -1) do
      delete data_export_path(@data_export1),
             as: :turbo_stream
    end
    assert_response :success
  end

  test 'should not delete export without valid authorization' do
    sign_in users(:jane_doe)
    assert_no_difference('DataExport.count') do
      delete data_export_path(@data_export1),
             as: :turbo_stream
    end
    assert_response :unauthorized
  end
end
