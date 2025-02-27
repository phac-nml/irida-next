# frozen_string_literal: true

# Handles content type detection and preview capabilities for file attachments
# This concern provides methods to determine if and how different file types
# can be previewed in the application interface.
#
# @example Usage in a controller
#   class MyController < ApplicationController
#     include FileFormatHandler
#
#     def show
#       @preview_type = determine_preview_type(file.content_type)
#       @previewable = previewable?(file.content_type)
#     end
#   end
module FileFormatHandler
  extend ActiveSupport::Concern

  PREVIEWABLE_TYPES = {
    'image' => :image,
    'text' => :text,
    'fasta' => :text,
    'fastq' => :text,
    'genbank' => :text,
    'json' => :json,
    'csv' => :csv,
    'tsv' => :tsv,
    'spreadsheet' => :excel
  }.freeze

  COPYABLE_TYPES = %w[text json csv tsv fasta fastq genbank].freeze

  def determine_preview_type(format)
    PREVIEWABLE_TYPES.find { |key, _| format.start_with?(key) }&.last
  end

  def previewable?(format)
    determine_preview_type(format).present?
  end

  def copyable?(format)
    COPYABLE_TYPES.include?(format)
  end
end
