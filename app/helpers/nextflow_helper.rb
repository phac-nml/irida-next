# frozen_string_literal: true

# Helper to render a Nextflow pipeline form
module NextflowHelper
  SCHEMA_PATH = 'test/fixtures/files/nextflow/'
  def form_input(name, property, required)
    return checkbox_input(name, property) if property['type'] == 'boolean'

    return file_input(name, property, required) if property['format'].present? && property['format'] == 'file-path'

    text_input(name, property, required)
  end

  def text_input(name, property, required)
    viral_text_input(label: property['description'], name:, type: 'text', required:, help_text: property['help_text'],
                     hidden: property['hidden'])
  end

  def checkbox_input(name, property)
    viral_checkbox(
      name: "metadata[#{name}]",
      label: property['description'],
      default: property['default'],
      pattern: property['pattern'],
      help_text: property['help_text'],
      hidden: property['hidden'],
      value: name
    )
  end

  def file_input(name, property, required)
    viral_file_input(
      label: property['description'],
      name: "metadata[#{name}]",
      pattern: property['pattern'],
      help_text: property['help_text'],
      hidden: property['hidden'],
      required:
    )
  end

  def samplesheet_schema(given_path)
    path = File.basename(given_path)
    JSON.parse(Rails.root.join(SCHEMA_PATH, path).read)
  end
end
