# frozen_string_literal: true

module Layout
  # A breadcrumb component for displaying navigation trails.
  class BreadcrumbComponent < Component
    # @param links [Array<Hash>] A list of hashes, each containing a `:name` and `:path`.
    def initialize(links:)
      @links = links
      validate_links!
    end

    def render?
      !@links.empty?
    end

    private

    def validate_links!
      raise ArgumentError, 'links must be an array' unless @links.is_a?(Array)
      return if @links.empty?
      return if @links.all? { |link| link.is_a?(Hash) && link.key?(:name) && link.key?(:path) }

      raise ArgumentError, 'All links must be hashes with :name and :path keys'
    end
  end
end
