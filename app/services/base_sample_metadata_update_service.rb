# frozen_string_literal: true

# Base service for metadata update service shared logic
class BaseSampleMetadataUpdateService < BaseService
  def initialize(user = nil, params = {})
    super
  end

  private

  def perform_metadata_update(sample, metadata, force_update) # rubocop:disable Metrics/MethodLength
    metadata_changes = { added: [], updated: [], deleted: [], not_updated: [], unchanged: [] }
    sample.with_lock do
      metadata.each do |key, value|
        validate_metadata_value(key, value, sample.name)
        key = strip_whitespaces(key.to_s.downcase)
        value = strip_whitespaces(value.to_s) # remove data types
        status = get_metadata_change_status(sample, key, value, force_update)
        next unless status

        metadata_changes[status] << key
        if %i[updated added].include?(status)
          add_metadata_to_sample(sample, key, value)
        elsif status == :deleted
          remove_metadata_from_sample(sample, key)
        end
      end
      sample.save
    end
    metadata_changes
  end

  def remove_metadata_from_sample(sample, key)
    sample.metadata.delete(key)
    sample.metadata_provenance.delete(key)
  end

  def add_metadata_to_sample(sample, key, value)
    sample.metadata_provenance[key] =
      if @analysis_id.nil?
        { source: 'user', id: current_user.id, updated_at: Time.current }
      else
        { source: 'analysis', id: @analysis_id, updated_at: Time.current }
      end
    sample.metadata[key] = value
  end

  def get_metadata_change_status(sample, key, value, force_update) # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    if value.blank?
      :deleted if sample.field?(key)
    elsif sample.metadata_provenance.key?(key) && @analysis_id.nil? &&
          sample.metadata_provenance[key]['source'] == 'analysis'
      :not_updated
    elsif sample.field?(key) && sample.metadata[key] == value
      force_update ? :updated : :unchanged
    else
      sample.field?(key) ? :updated : :added
    end
  end

  def update_namespace_metadata_summary(project_namespace, deleted_metadata, added_metadata, by_one)
    project_namespace.update_metadata_summary_by_update_service(deleted_metadata,
                                                                added_metadata,
                                                                by_one)
  end
end
