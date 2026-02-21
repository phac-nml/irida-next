# frozen_string_literal: true

module GlobalSearch
  # DTO for a single global search hit.
  class Result
    attr_reader :type,
                :record_id,
                :title,
                :subtitle,
                :url,
                :match_tags,
                :score_bucket,
                :updated_at,
                :context_label,
                :context_url

    # rubocop:disable Metrics/ParameterLists
    def initialize(
      type:, record_id:, title:, subtitle:, url:, match_tags:, score_bucket:, updated_at:, context_label: nil,
      context_url: nil
    )
      @type = type
      @record_id = record_id
      @title = title
      @subtitle = subtitle
      @url = url
      @match_tags = match_tags
      @score_bucket = score_bucket
      @updated_at = updated_at
      @context_label = context_label
      @context_url = context_url
    end
    # rubocop:enable Metrics/ParameterLists

    def to_h
      {
        type:,
        record_id:,
        title:,
        subtitle:,
        url:,
        match_tags:,
        score_bucket:,
        updated_at: updated_at&.iso8601,
        context_label:,
        context_url:
      }
    end
  end
end
