# frozen_string_literal: true

module NamespaceRow
  # Namespace Row Contents component
  class ContentsComponent < Component
    include NamespacePathHelper

    def initialize(namespace:, full_name: false, icon_size: :small, search_params: nil)
      @namespace = namespace
      @full_name = full_name
      @icon_size = icon_size
      @search_params = search_params
    end

    # Base Tailwind classes applied to all count "pill" elements.
    BASE_COUNT_PILL_CLASSES = %w[
      items-center text-sm inline-flex justify-center p-2 py-1 rounded-full font-mono
      text-slate-800 dark:text-slate-200
      group-focus-visible:ring-3 group-focus-visible:ring-black outline-none
      dark:group-focus-visible:ring-white group-focus-visible:ring-offset-2
      dark:group-focus-visible:ring-offset-slate-900
    ].freeze

    # Variant classes keyed by pill kind.
    VARIANT_COUNT_PILL_CLASSES = {
      groups: %w[bg-amber-100 dark:bg-amber-700].freeze,
      projects: %w[bg-fuchsia-100 dark:bg-fuchsia-700].freeze,
      samples: %w[samples-count bg-blue-100 dark:bg-blue-700].freeze
    }.freeze

    EMPTY_ARRAY = [].freeze

    def avatar_icon
      if @namespace.group_namespace?
        pathogen_icon(:squares_four, size: :md, color: :subdued)
      elsif @namespace.project_namespace?
        pathogen_icon(Project.icon, size: :md, color: :subdued)
      end
    end

    # Builds the Tailwind class string for the small count "pill" spans used in the row.
    #
    # @param kind [Symbol, String] the pill type; one of :groups, :projects, or :samples
    # @return [String] space-joined list of base and variant classes
    def count_pill_classes(kind)
      variant_classes = VARIANT_COUNT_PILL_CLASSES[kind.to_sym] || EMPTY_ARRAY
      (BASE_COUNT_PILL_CLASSES + variant_classes).join(' ')
    end
  end
end
