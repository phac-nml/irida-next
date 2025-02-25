# frozen_string_literal: true

require 'test_helper'

class ContentTypeHandlerTest < ActionDispatch::IntegrationTest
  # Create a dummy class that includes the ContentTypeHandler module to test its methods.
  class DummyClass
    include ContentTypeHandler
  end

  setup do
    @dummy = DummyClass.new
  end

  test 'determine_preview_type returns correct preview for image content' do
    assert_equal :image, @dummy.determine_preview_type('image/png')
  end

  test 'determine_preview_type returns correct preview for text content' do
    assert_equal :text, @dummy.determine_preview_type('text/plain')
  end

  test 'determine_preview_type returns correct preview for JSON content' do
    assert_equal :json, @dummy.determine_preview_type('application/json')
  end

  test 'determine_preview_type returns correct preview for CSV content' do
    assert_equal :csv, @dummy.determine_preview_type('text/csv')
  end

  test 'determine_preview_type returns correct preview for Excel content' do
    assert_equal :excel,
                 @dummy.determine_preview_type('application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
  end

  test 'determine_preview_type returns nil for unknown content type' do
    assert_nil @dummy.determine_preview_type('application/pdf')
  end

  test 'previewable? returns true for previewable content' do
    assert @dummy.previewable?('text/plain')
    assert @dummy.previewable?('image/jpeg')
  end

  test 'previewable? returns false for non-previewable content' do
    assert_not @dummy.previewable?('application/pdf')
  end

  test 'copyable? returns true for copyable content' do
    assert @dummy.copyable?('text/plain')
    assert @dummy.copyable?('text/csv')
  end

  test 'copyable? returns false for non-copyable content' do
    assert_not @dummy.copyable?('image/png')
  end
end
