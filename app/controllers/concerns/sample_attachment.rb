# frozen_string_literal: true

# Common Sample Attachment Logic
module SampleAttachment
  extend ActiveSupport::Concern
  include Metadata
  include AttachmentSearchable

  def list_sample_attachments
    @render_individual_attachments = filter_requested?
    all_attachments = load_attachments
    @query = attachments_query(@sample)
    @has_attachments = all_attachments.any?
    @search_params = attachment_search_params

    @pagy, @attachments = @query.results(limit: params[:limit] || 20, page: params[:page] || 1)
    @results_message = attachments_results_message

    setup_ransack_for_attachments_form(all_attachments)
  end

  private

  def load_attachments
    if filter_requested?
      @sample.attachments.all
    else
      @sample.attachments.where.not(Attachment.arel_table[:metadata].contains({ direction: 'reverse' }))
    end
  end
end
