# frozen_string_literal: true

# Helper to render a Nextflow pipeline form
module NextflowHelper
  # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
  def form_input(container, name, property, required, instance)
    value = instance.present? ? instance['workflow_params'][name.to_s] : property[:default]

    if property[:type] == 'boolean'
      return viral_prefixed_boolean(
        form: container, name:,
        value: ActiveModel::Type::Boolean.new.cast(value)
      ) do |input|
               input.with_prefix do
                 format_name_as_arg(name)
               end
             end
    end

    if property[:enum].present?
      return viral_prefixed_select(form: container, name:, options: property[:enum],
                                   selected_value: value) do |select|
               select.with_prefix do
                 format_name_as_arg(name)
               end
             end
    end

    viral_prefixed_text_input(form: container, name:, required:, pattern: property[:pattern],
                              value:) do |input|
      input.with_prefix do
        format_name_as_arg(name)
      end
    end
  end

  # rubocop:enable Metrics/MethodLength, Metrics/AbcSize

  def checkbox_input(fields, name, property)
    viral_checkbox(
      container: fields,
      name:,
      label: property[:description],
      value: true
    )
  end

  def format_name_as_arg(name)
    name.length > 1 ? "--#{name}" : "-#{name}"
  end

  def text_for(value)
    return '' if value.nil?

    if value.instance_of?(String)
      value
    else
      value[I18n.locale.to_s]
    end
  end
end
