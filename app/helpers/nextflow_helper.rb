# frozen_string_literal: true

# Helper to render a Nextflow pipeline form
module NextflowHelper
  def form_input(container, name, property, required, instance) # rubocop:disable Metrics/MethodLength
    value = instance.present? ? instance['workflow_params'][name.to_s] : property[:default]

    if property[:enum].present?
      return viral_prefixed_select(form: container, name:, options: property[:enum],
                                   selected_value: value) do |select|
               select.with_prefix do
                 format_name_as_arg(name)
               end
             end
    end

    data = { 'metadata-header-name': name.to_s.remove('_header') } if metadata_header?(name.to_s)

    viral_prefixed_text_input(form: container, name:, required:, pattern: property[:pattern],
                              value:, data:) do |input|
      input.with_prefix do
        format_name_as_arg(name)
      end
    end
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
    /metadata_[0-9]+_header/.match?(header_name.to_s) && Flipper.enabled?(:update_nextflow_metadata_param)
  end
end
