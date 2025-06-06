# frozen_string_literal: true

# Common Sample Attachment Logic
module SampleAttachment
  extend ActiveSupport::Concern
  include Metadata

  def list_sample_attachments
    @render_individual_attachments = filter_requested?
    all_attachments = load_attachments
    @has_attachments = all_attachments.count.positive?
    @q = all_attachments.ransack(params[:q])
    set_attachment_default_sort
    @pagy, @sample_attachments = pagy_with_metadata_sort(@q.result, Attachment)
  end

  private

  def filter_requested?
    params.dig(:q, :puid_or_file_blob_filename_cont).present?
  end

  def load_attachments
    if filter_requested?
      @sample.attachments.all
    else
      @sample.attachments.where.not(Attachment.arel_table[:metadata].contains({ direction: 'reverse' }))
    end
  end

  def set_attachment_default_sort
    @q.sorts = 'created_at desc' if @q.sorts.empty?
  end
end
