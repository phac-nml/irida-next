# frozen_string_literal: true

# Helper to render a Nextflow pipeline form
module NextflowHelper
  SCHEMA_PATH = 'test/fixtures/files/nextflow/'

  def form_input(container, name, property, required)
    return checkbox_input(container, name, property) if property['type'] == 'boolean'

    if property['enum'].present?
      return viral_select(container:, name:, options: property['enum'], selected_value: property['default'])
    end

    viral_text_input(container:, name:, required:, pattern: property['pattern'])
  end

  def checkbox_input(fields, name, property)
    viral_checkbox(
      container: fields,
      name:,
      label: property['description'],
      value: true
    )
  end

  def samplesheet_schema(given_path)
    path = File.basename(given_path)
    JSON.parse(Rails.root.join(SCHEMA_PATH, path).read)
  end

  def format_name_as_arg(name)
    name.length > 1 ? "--#{name}" : "-#{name}"
  end
end
