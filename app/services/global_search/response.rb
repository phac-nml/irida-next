# frozen_string_literal: true

module GlobalSearch
  # Search response DTO.
  class Response
    attr_reader :query, :meta, :results

    def initialize(query:, meta:, results:)
      @query = query
      @meta = meta
      @results = results
    end
  end
end
