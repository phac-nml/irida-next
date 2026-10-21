# frozen_string_literal: true

# Helper to render a Nextflow pipeline form
module NextflowHelper
  def form_input(container, name, property, instance, describedby: nil)
    value = instance.present? ? instance['workflow_params'][name.to_s] : property[:default]
    options = {
      class: 'workflow-parameter-input',
      aria: { required: property[:required] ? 'true' : nil, describedby: }
    }

    return container.select(name, property[:enum], { selected: value }, options) if property[:enum].present?

    data = { 'metadata-header-name': name.to_s.remove('_header') } if metadata_header?(name.to_s)
    container.text_field(name, **options, value:, pattern: property[:pattern], data:)
  end

  def format_name_as_arg(name)
    name.length > 1 ? "--#{name}" : "-#{name}"
  end

  def formatted_workflow_param(property, original_value)
    if !property.key?(:enum) || property[:enum].include?(original_value)
      original_value
    else
      original_value = '' if original_value.blank?
      index = property[:enum].find_index { |(_label, value)| value == original_value }
      index.nil? ? original_value : property[:enum][index][0]
    end
  end

  def metadata_header?(header_name)
    /metadata_[0-9]+_header/.match?(header_name.to_s)
  end
end
