# frozen_string_literal: true

# Helper to render a Nextflow pipeline form
module NextflowHelper
  SCHEMA_PATH = 'test/fixtures/files/nextflow/'

  def form_input(container, name, property, required)
    return checkbox_input(container, name, property) if property['type'] == 'boolean'

    if property['enum'].present?
      return viral_select(container:, name:, options: property['enum'], hidden: property['hidden'],
                          selected_value: property['default'], help_text: property['help_text'])
    end

    viral_text_input(container:, name:, required:, pattern: property['pattern'])
  end

  def checkbox_input(_fields, name, property)
    viral_checkbox(
      name: "metadata[#{name}]",
      label: property['description'],
      default: property['default'],
      help_text: property['help_text'],
      value: name
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
