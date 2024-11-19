# frozen_string_literal: true

module Pathogen
  class TabsPanel < Pathogen::Component
    BODY_TAG_DEFAULT = :ul

    TAG_DEFAULT = :nav
    TAG_OPTIONS = [TAG_DEFAULT, :div].freeze

    renders_many :tabs, lambda { |selected: false, **system_arguments|
      # system_arguments[:classes] = tab_nav_tab_classes(system_arguments[:classes])
      Pathogen::Tab.new(
        list: true,
        selected: selected,
        **system_arguments
      )
    }

    def initialize(label:, tag: TAG_DEFAULT, body_arguments: {}, **system_arguments)
      # @align = EXTRA_ALIGN_DEFAULT
      @system_arguments = system_arguments
      @body_arguments = body_arguments

      @system_arguments[:tag] = fetch_or_fallback(TAG_OPTIONS, tag, TAG_DEFAULT)
      # @system_arguments[:classes] = tab_nav_classes(system_arguments[:classes])

      @body_arguments[:tag] = BODY_TAG_DEFAULT
      # @body_arguments[:classes] = tab_nav_body_classes(body_arguments[:classes])

      # aria_label_for_page_nav(label)
    end

    # def before_render
    #   # Eagerly evaluate content to avoid https://github.com/primer/view_components/issues/1790
    #   content

    #   super
    # end
  end
end
