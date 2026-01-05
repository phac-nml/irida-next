# frozen_string_literal: true

class SelectWithAutoCompleteComponentPreview < ViewComponent::Preview
  include ActionView::Helpers::FormOptionsHelper

  def default # rubocop:disable Metrics/MethodLength
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

    options = options_for_select(sample_fields).concat(
      grouped_options_for_select(metadata_fields, selected_key = 'metadata.age') # rubocop:disable Lint/UselessAssignment
    )

    render_with_template(locals: {
                           options: options
                         })
  end
end
