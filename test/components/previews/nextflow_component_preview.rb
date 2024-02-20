# frozen_string_literal: true

class NextflowComponentPreview < ViewComponent::Preview
  # @param schema_file select :schema_file_options
  def default(schema_file: 'nextflow_schema.json')
    sample1 = Sample.find_by(id: 1)
    sample2 = Sample.find_by(id: 2)

    workflow = Struct.new(:name, :id, :description, :version, :metadata, :type, :type_version, :engine,
                          :engine_version, :url, :execute_loc)
    metadata = { workflow_name: 'irida-next-example', workflow_version: '1.0dev' }
    flow = workflow.new('phac-nml/iridanextexample', 1, 'IRIDA Next Example Pipeline', '1.0.1', metadata,
                        'NFL', 'DSL2', 'nextflow', '23.10.0',
                        'https://github.com/phac-nml/iridanextexample', 'azure')

    render_with_template(locals: {
                           schema_file:,
                           samples: [sample1, sample2],
                           workflow: flow
                         })
  end

  private

  def schema_file_options
    Rails.root.join('test/fixtures/files/nextflow').entries.select do |f|
      File.file?(File.join('test/fixtures/files/nextflow', f)) && f.to_s.starts_with?('nextflow_schema')
    end
  end
end
