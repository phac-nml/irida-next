# frozen_string_literal: true

require 'test_helper'
require 'tempfile'
require 'csv'

class SpreadsheetHelperTest < ActionView::TestCase
  include SpreadsheetHelper

  test 'raises error when no file is provided' do
    assert_raises(SpreadsheetParsingError, t('spreadsheet_helper.no_file')) do
      parse_spreadsheet(nil)
    end
  end

  test 'raises error when headers are missing in CSV file' do
    file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/spreadsheet_helper_test/missing_headers.csv'))
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    assert_raises(SpreadsheetParsingError, t('spreadsheet_helper.no_headers')) do
      parse_spreadsheet(blob)
    end
  end

  test 'successfully parses CSV file with valid data' do
    file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/spreadsheet_helper_test/good_csv.csv'))
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    result = parse_spreadsheet(blob)

    assert_equal 3, result.length
    assert_equal %w[name age city], result[0]
    assert_equal({ 'name' => 'Alice', 'age' => 30, 'city' => 'New York' }, result[1])
    assert_equal({ 'name' => 'Bob', 'age' => 25, 'city' => 'London' }, result[2])
  end

  test 'skips empty rows in data' do
    file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/spreadsheet_helper_test/missing_rows.csv'))
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    result = parse_spreadsheet(blob)

    assert_equal 3, result.length # headers + 2 data rows
    assert_equal %w[name age], result[0]
  end

  test 'handles rows with incorrect number of columns' do
    file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/spreadsheet_helper_test/incorrect_cols.csv'))
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    result = parse_spreadsheet(blob)

    assert_equal 3, result.length # Only headers and the valid row
    assert_equal %w[name age city], result[0]
    assert_equal({ 'name' => 'Alice', 'age' => 30, 'city' => nil }, result[1])
    assert_equal({ 'name' => 'Bob', 'age' => 25, 'city' => 'London' }, result[2])
  end

  test 'raises error for unsupported file format' do
    file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/spreadsheet_helper_test/unsupported.txt'))
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )

    error = assert_raises(SpreadsheetParsingError) do
      parse_spreadsheet(blob)
    end
    assert_match(t('spreadsheet_helper.unknown_file_format', extension: File.extname(file.original_filename)),
                 error.message)
  end

  test 'parses CSV file with only headers' do
    file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/spreadsheet_helper_test/only_headers.csv'))
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    result = parse_spreadsheet(blob)
    assert_equal 1, result.length
    assert_equal %w[name age city], result[0]
  end

  test 'raises error when file is completely empty' do
    file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/spreadsheet_helper_test/empty.csv'))
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    error = assert_raises(SpreadsheetParsingError) do
      parse_spreadsheet(blob)
    end
    assert_match t('spreadsheet_helper.no_headers'), error.message
  end

  test 'parses Excel file with valid data' do
    file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/spreadsheet_helper_test/good.xlsx'))
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    result = parse_spreadsheet(blob)

    assert_equal 3, result.length # headers + 2 data rows
    assert_equal %w[name age city], result[0]
    assert_equal({ 'name' => 'Alice', 'age' => 30, 'city' => 'New York' }, result[1])
    assert_equal({ 'name' => 'Bob', 'age' => 25, 'city' => 'London' }, result[2])
  end

  test 'raises error when Excel file is missing headers' do
    file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/spreadsheet_helper_test/missing_headers.xlsx'))
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    error = assert_raises(SpreadsheetParsingError) do
      parse_spreadsheet(blob)
    end
    assert_match t('spreadsheet_helper.no_headers'), error.message
  end

  test 'raises error when Excel file has only headers' do
    file = Rack::Test::UploadedFile.new(Rails.root.join('test/fixtures/files/spreadsheet_helper_test/only_headers.xlsx'))
    blob = ActiveStorage::Blob.create_and_upload!(
      io: file,
      filename: file.original_filename,
      content_type: file.content_type
    )
    result = parse_spreadsheet(blob)

    assert_equal 1, result.length
    assert_equal %w[name age city], result[0]
  end
end
