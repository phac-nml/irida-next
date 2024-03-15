# frozen_string_literal: true

# Helper to render a Nextflow pipeline form
module NextflowHelper
  SCHEMA_PATH = 'test/fixtures/files/nextflow/'

  def form_input(container, name, property, required)
    return checkbox_input(container, name, property) if property['type'] == 'boolean'

    if property['enum'].present?
      return viral_select_group(form: container, name:, options: property['enum'],
                                selected_value: property['default']) do |select|
               select.with_prefix do
                 name
               end
             end
    end

    viral_input_group(form: container, name:, required:, pattern: property['pattern'],
                      value: property['default']) do |input|
      input.with_prefix do
        name
      end
    end
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
