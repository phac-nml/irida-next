# frozen_string_literal: true

module AdvancedSearch
  module V2
    # Host adapter: renders the advanced search trigger + Viral dialog, and mounts the
    # host-agnostic BuilderComponent inside it. Drives the builder lifecycle through the
    # advanced-search--v2--dialog Stimulus controller (open/close/dirty-close confirmation).
    #
    # Mirrors the public argument surface of AdvancedSearch::V1::Component so the versioned
    # AdvancedSearchComponent entrypoint can dispatch to either implementation.
    class DialogComponent < ::Component
      # rubocop:disable-next Metrics/ParameterLists
      def initialize(form:, search:, fields: nil, sample_fields: [], metadata_fields: [], open: false, status: true,
                     subject: nil)
        @form = form
        @search = search
        @fields = fields
        @sample_fields = sample_fields
        @metadata_fields = metadata_fields
        @open = open
        @status = status
        @subject = subject
      end
    end
  end
end
