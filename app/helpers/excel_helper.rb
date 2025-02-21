# frozen_string_literal: true

# ExcelHelper is a helper module that provides methods for parsing Excel files.
module ExcelHelper
  SUPPORTED_FORMATS = %w[.xlsx .xls .csv].freeze

  class ExcelParsingError < StandardError; end

  def parse_excel_file(file)
    raise ExcelParsingError, 'No file provided' if file.blank?

    extension = File.extname(file.filename.to_s).downcase
    # raise ExcelParsingError, "Unsupported file format: #{extension}" unless SUPPORTED_FORMATS.include?(extension)

    # Create a tempfile to handle ActiveStorage blob
    data = []
    file.open do |f|
      spreadsheet = Roo::Spreadsheet.open(
        f.path,
        extension: extension,
        file_warning: :ignore
      )
      headers = spreadsheet.row(1).map(&:presence).compact
      raise ExcelParsingError, 'No headers found in file' if headers.empty?

      data << headers

      (2..spreadsheet.last_row).each do |i|
        row_data = spreadsheet.row(i)
        next if row_data.all?(&:blank?) # Skip empty rows

        # Only process rows that have the same number of columns as headers
        if row_data.length == headers.length
          row = [headers, row_data].transpose.to_h
          data << row
        end
      end
    end

    data
  rescue Roo::Error => e
    Rails.logger.error "Excel parsing error: #{e.message}"
    raise ExcelParsingError, "Failed to parse Excel file: #{e.message}"
  rescue StandardError => e
    Rails.logger.error "Unexpected error parsing Excel file: #{e.class} - #{e.message}"
    raise ExcelParsingError, 'An unexpected error occurred while parsing the file'
  end
end
