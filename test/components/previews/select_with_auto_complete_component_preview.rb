# frozen_string_literal: true

class SelectWithAutoCompleteComponentPreview < ViewComponent::Preview
  def default
    render_with_template(locals: {
                           fields: %w[name puid created_at updated_at attachments_updated_at]
                         })
  end

  def with_groups
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

    render_with_template(locals: {
                           fields: metadata_fields.merge({ 'Sample fields': sample_fields })
                         })
  end
end
