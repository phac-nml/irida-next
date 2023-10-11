# frozen_string_literal: true

class NextflowComponentPreview < ViewComponent::Preview
  # @param schema_file select :schema_file_options
  def default(schema_file: 'nextflow_schema.json')
    render_with_template(locals: {
                           schema_file:
                         })
  end

  private

  def schema_file_options
    Rails.root.join('test/fixtures/files/nextflow').entries.select do |f|
      File.file?(File.join('test/fixtures/files/nextflow', f)) && f.to_s.starts_with?('samplesheet')
    end
  end
end
