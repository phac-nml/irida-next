# frozen_string_literal: true

# Controller for managing individual attachment previews and displays.
# This controller handles the presentation of attachments based on their format
# and supports various file types including text, images, and specialized formats
# like FASTA, FASTQ, and GenBank files.
#
# The controller uses the Attachable concern for handling breadcrumb navigation
# and context management for attachments in the application.
#
# @see Attachable
# @see Attachment
class AttachmentController < ApplicationController
  layout 'attachment'

  include Attachable

  # Displays a preview of the attachment if the file exists and preview is enabled.
  # The preview format is determined by the attachment's metadata format.
  #
  # Supported preview formats:
  # - text (txt, rtf)
  # - image (png, jpg, jpeg, gif, bmp, tiff, svg, webp)
  # - fasta
  # - fastq
  # - genbank
  # - json
  # - csv
  # - tsv
  # - spreadsheet (xls, xlsx)
  #
  # @return [void]
  # @raise [ActionController::UnknownFormat] if the format is not supported
  def show
    @attachments_preview_enabled ||= Flipper.enabled?(:attachments_preview)
    return handle_preview if @attachment.present? && @attachments_preview_enabled

    handle_not_found
  end

  private

  # Handles the preview rendering based on the attachment format
  #
  # @return [void]
  def handle_preview
    format = @attachment.metadata['format']
    render "#{format}_preview"
  end

  # Handles the case when the attachment is not found or preview is not available
  #
  # @return [void]
  def handle_not_found
    redirect_back fallback_location: request.referer || root_path,
                  alert: I18n.t('attachment.show.file_not_found')
    nil
  end
end
