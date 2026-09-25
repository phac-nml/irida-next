# frozen_string_literal: true

# Shared logic for building Attachment::Query params and rendering attachment search results.
module AttachmentSearchable
  extend ActiveSupport::Concern

  include SearchResultsMessage

  private

  def filter_requested?
    params.dig(:q, :puid_or_file_blob_filename_cont).present?
  end

  def attachments_query(attachable)
    Attachment::Query.new(attachment_search_params.merge(request:, attachables: [attachable]))
  end

  def attachment_search_params
    search_params = {}
    search_params[:puid_or_file_blob_filename_cont] = params.dig(:q, :puid_or_file_blob_filename_cont)
    search_params[:sort] = params.dig(:q, :s)

    groups_attributes = attachment_advanced_search_groups_attributes
    search_params[:groups_attributes] = groups_attributes if groups_attributes.present?

    search_params.compact
  end

  def attachment_advanced_search_groups_attributes
    groups_attributes = params.dig(:q, :groups_attributes)
    return if groups_attributes.blank?

    # Advanced search groups use dynamic nested keys; preserve all keys.
    groups_attributes.respond_to?(:to_unsafe_h) ? groups_attributes.to_unsafe_h : groups_attributes
  end

  def setup_ransack_for_attachments_form(all_attachments)
    # Create Ransack object from request params for UI component compatibility
    @q = all_attachments.ransack(params[:q])
    # Sync search values from custom Query to Ransack for accurate form display
    @q.puid_or_file_blob_filename_cont = @query.puid_or_file_blob_filename_cont
    # Set default sort order if none provided
    @q.sorts = 'created_at desc' if @q.sorts.empty?
  end

  def attachments_results_message
    return advanced_search_results_message if @query.advanced_query?

    return if @query.puid_or_file_blob_filename_cont.blank?

    quick_search_results_message(@query.puid_or_file_blob_filename_cont)
  end
end
