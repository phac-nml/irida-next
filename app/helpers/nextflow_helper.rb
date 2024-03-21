# frozen_string_literal: true

# Helper to render a Nextflow pipeline form
module NextflowHelper
  SCHEMA_PATH = 'test/fixtures/files/nextflow/'

  def form_input(container, name, property, required)
    if property['type'] == 'boolean'
      return viral_prefixed_boolean(form: container, name:, value: property['default']) do |input|
        input.with_prefix do
          name
        end
      end
    end

    if property['enum'].present?
      return viral_prefixed_select(form: container, name:, options: property['enum'],
                                   selected_value: property['default']) do |select|
               select.with_prefix do
                 name
               end
             end
    end

    viral_prefixed_text_input(form: container, name:, required:, pattern: property['pattern'],
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
