# frozen_string_literal: true

require 'test_helper'

# Test suite for the ContentTypeHandler module, ensuring it correctly determines preview types and content properties.
class FileFormatHandlerTest < ActionDispatch::IntegrationTest
  # Create a dummy class that includes the FileFormatHandler module to test its methods.
  class DummyClass
    include FileFormatHandler
  end

  setup do
    @dummy = DummyClass.new
  end

  test 'determine_preview_type returns correct preview for image content' do
    assert_equal :image, @dummy.determine_preview_type('imageng')
  end

  test 'determine_preview_type returns correct preview for text content' do
    assert_equal :text, @dummy.determine_preview_type('text')
  end

  test 'determine_preview_type returns correct preview for JSON content' do
    assert_equal :json, @dummy.determine_preview_type('json')
  end

  test 'determine_preview_type returns correct preview for CSV content' do
    assert_equal :csv, @dummy.determine_preview_type('csv')
  end

  test 'determine_preview_type returns correct preview for Excel content' do
    assert_equal :excel,
                 @dummy.determine_preview_type('spreadsheet')
  end

  test 'determine_preview_type returns nil for unknown content type' do
    assert_nil @dummy.determine_preview_type('application/pdf')
  end

  test 'previewable? returns true for previewable content' do
    assert @dummy.previewable?('text')
    assert @dummy.previewable?('image')
  end

  test 'previewable? returns false for non-previewable content' do
    assert_not @dummy.previewable?('unknown')
  end

  test 'copyable? returns true for copyable content' do
    assert @dummy.copyable?('text')
    assert @dummy.copyable?('json')
    assert @dummy.copyable?('csv')
    assert @dummy.copyable?('tsv')
  end

  test 'copyable? returns false for non-copyable content' do
    assert_not @dummy.copyable?('image')
  end
end
