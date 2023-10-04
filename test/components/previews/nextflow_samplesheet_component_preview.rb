# frozen_string_literal: true

require 'csv'
class NextflowSamplesheetComponentPreview < ViewComponent::Preview
  def default(samplesheet_file: 'samplesheet.csv')
    render_with_template(locals: {
                           samplesheet_file:
                         })
  end
end
