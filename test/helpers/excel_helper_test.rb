# frozen_string_literal: true

require 'test_helper'
require 'tempfile'
require 'csv'

class ExcelHelperTest < ActionView::TestCase
  include ExcelHelper

  test 'raises error when no file is provided' do
    assert_raises(ExcelParsingError, 'No file provided') do
      parse_excel_file(nil)
    end
  end

  test 'raises error when headers are missing in CSV file' do
    Tempfile.create(['empty_headers', '.csv']) do |tempfile|
      # Write CSV with blank header row and one data row.
      tempfile.write(" , , \n1,2,3")
      tempfile.rewind
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        filename: 'empty_headers.csv',
        type: 'text/csv',
        tempfile: tempfile
      )
      assert_raises(ExcelParsingError, 'No headers found in file') do
        parse_excel_file(uploaded_file)
      end
    end
  end

  test 'handles Roo error by raising ExcelParsingError with custom message' do
    Tempfile.create(['dummy', '.csv']) do |tempfile|
      tempfile.write("name,age\nAlice,30")
      tempfile.rewind
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        filename: 'dummy.csv',
        type: 'text/csv',
        tempfile: tempfile
      )
      # Stub open_spreadsheet to simulate a Roo::Error
      def open_spreadsheet(_path, _extension)
        raise Roo::Error, 'simulated roo error'
      end

      error = assert_raises(ExcelParsingError) do
        parse_excel_file(uploaded_file)
      end
      assert_match('An unexpected error occurred while parsing the file', error.message)
    end
  end

  test 'handles unexpected errors by raising ExcelParsingError with generic message' do
    Tempfile.create(['dummy', '.csv']) do |tempfile|
      tempfile.write("name,age\nAlice,30")
      tempfile.rewind
      uploaded_file = ActionDispatch::Http::UploadedFile.new(
        filename: 'dummy.csv',
        type: 'text/csv',
        tempfile: tempfile
      )
      # Stub extract_headers to trigger a StandardError
      original_extract_headers = method(:extract_headers)
      define_singleton_method(:extract_headers) do |*args|
        raise StandardError, 'unexpected error'
      end

      error = assert_raises(ExcelParsingError) do
        parse_excel_file(uploaded_file)
      end
      assert_equal 'An unexpected error occurred while parsing the file', error.message
      define_singleton_method(:extract_headers, original_extract_headers)
    end
  end
end
