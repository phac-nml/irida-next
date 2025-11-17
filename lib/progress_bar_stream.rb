# frozen_string_literal: true

# Utility helpers for generating consistent DOM ids for Turbo-driven progress bars.
module ProgressBarStream
  module_function

  # Builds a sanitized DOM id for a given broadcast target so Turbo Stream
  # updates can precisely target the correct element.
  #
  # @param broadcast_target [String, #to_s] Turbo broadcast stream identifier
  # @return [String] DOM-safe identifier that is stable for the stream
  def dom_id_for(broadcast_target)
    return 'progress-bar' if broadcast_target.blank?

    sanitized_target = broadcast_target.to_s.gsub(/[^a-zA-Z0-9_-]/, '-')
    "#{sanitized_target}-progress-bar"
  end
end
