# frozen_string_literal: true

require 'csv'
class NextflowSamplesheetComponentPreview < ViewComponent::Preview
  # @param samplesheet_file select :samplesheet_file_options

  def default(samplesheet_file: 'samplesheet.csv')
    headers, *samples = CSV.read(
      Rails.root.join('test', 'fixtures', 'files', 'nextflow', samplesheet_file)
    )

    render_with_template(locals: {
                           headers:,
                           samples:
                         })
  end

  def samplesheet_file_options
    Rails.root.join('test/fixtures/files/nextflow').entries.select do |f|
      File.file?(File.join('test/fixtures/files/nextflow',
                           f)) && f.to_s.starts_with?('samplesheet') && f.to_s.ends_with?('.csv')
    end
  end
end
