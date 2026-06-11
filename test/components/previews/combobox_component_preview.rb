# frozen_string_literal: true

class ComboboxComponentPreview < ViewComponent::Preview
  include ActionView::Helpers::FormOptionsHelper

  def default
    render_with_template(locals: default_locals)
  end

  def with_disabled_options
    render_with_template(
      template: 'combobox_component_preview/default',
      locals: default_locals(
        label: 'Field with disabled options',
        options: disabled_options_preview_options
      )
    )
  end

  def disabled
    render_with_template(
      template: 'combobox_component_preview/default',
      locals: default_locals(
        label: 'Disabled combobox',
        combobox_arguments: { disabled: true }
      )
    )
  end

  private

  def default_locals(label: 'Metadata field', options: grouped_metadata_options, combobox_arguments: {})
    {
      label: label,
      options: options,
      combobox_arguments: combobox_arguments
    }
  end

  def disabled_options_preview_options
    options_for_select(
      [
        ['First enabled option', 'first-enabled-option'],
        ['Disabled option', 'disabled-option'],
        ['Second enabled option', 'second-enabled-option'],
        ['Another disabled option', 'another-disabled-option'],
        ['Enabled option', 'enabled-option'],
        ['Last disabled option', 'last-disabled-option'],
        ['Third enabled option', 'third-enabled-option']
      ],
      { disabled: %w[disabled-option another-disabled-option last-disabled-option] }
    )
  end

  def grouped_metadata_options
    sample_fields = %w[name puid created_at updated_at attachments_updated_at]
    metadata_fields = { 'Metadata fields': [['age', 'metadata.age'],
                                            ['country', 'metadata.country'],
                                            ['earliest_date', 'metadata.earliest_date'],
                                            ['food', 'metadata.food'],
                                            ['gender', 'metadata.gender'],
                                            ['insdc_accession', 'metadata.insdc_accession'],
                                            ['ncbi_accession', 'metadata.ncbi_accession'],
                                            ['onset', 'metadata.onset'],
                                            ['patient_age', 'metadata.patient_age'],
                                            ['patient_sex', 'metadata.patient_sex'],
                                            ['wgs_id', 'metadata.wgs_id']] }

    options_for_select(sample_fields).concat(
      grouped_options_for_select(metadata_fields, selected_key = 'metadata.age') # rubocop:disable Lint/UselessAssignment
    )
  end
end
