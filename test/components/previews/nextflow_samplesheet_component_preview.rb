# frozen_string_literal: true

require 'csv'
class NextflowSamplesheetComponentPreview < ViewComponent::Preview
  def default(samplesheet_file: 'samplesheet.csv')
    headers, *remainder = CSV.read(
      Rails.root.join('test', 'fixtures', 'files', 'nextflow', samplesheet_file)
    )

    samples = remainder.map do |row|
      {
        headers[0] => row[0],
        headers[1] => row[1],
        headers[2] => row[2],
        headers[3] => row[3]
      }
    end

    render_with_template(locals: {
                           headers:,
                           samples:
                         })
  end
end
