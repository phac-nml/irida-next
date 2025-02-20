# frozen_string_literal: true

# Handles content type detection and preview capabilities for file attachments
# This concern provides methods to determine if and how different file types
# can be previewed in the application interface.
#
# @example Usage in a controller
#   class MyController < ApplicationController
#     include ContentTypeHandler
#
#     def show
#       @preview_type = determine_preview_type(file.content_type)
#       @previewable = previewable?(file.content_type)
#     end
#   end
module ContentTypeHandler
  extend ActiveSupport::Concern

  PREVIEWABLE_TYPES = {
    'image/' => :image,
    'text/plain' => :text,
    'application/json' => :json,
    'text/csv' => :csv,
    'text/tab-separated-values' => :tsv
  }.freeze

  def determine_preview_type(content_type)
    PREVIEWABLE_TYPES.find { |key, _| content_type.start_with?(key) }&.last
  end

  def previewable?(content_type)
    determine_preview_type(content_type).present?
  end
end
