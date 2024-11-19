# frozen_string_literal: true

module Pathogen
  class TabsPanel < Pathogen::Component
    TAG_DEFAULT = :nav
    TAG_OPTIONS = [TAG_DEFAULT, :div].freeze

    WRAPPER_DEFAULT_CLASSES = '
      flex text-sm font-medium text-center border-b text-slate-500 border-slate-200
      dark:text-slate-400 dark:border-slate-700
    '

    BODY_TAG_DEFAULT = :ul
    BODY_DEFAULT_CLASSES = 'flex flex-wrap -mb-px'

    renders_many :tabs, lambda { |selected: false, **system_arguments|
      # system_arguments[:classes] = tab_nav_tab_classes(system_arguments[:classes])
      Pathogen::Tab.new(
        selected: selected,
        controls: @id,
        **system_arguments
      )
    }

    def initialize(id:, label: '', tag: TAG_DEFAULT, body_arguments: {}, **system_arguments)
      @id = id
      @system_arguments = system_arguments
      @body_arguments = body_arguments

      @system_arguments[:tag] = fetch_or_fallback(TAG_OPTIONS, tag, TAG_DEFAULT)
      @system_arguments[:classes] = class_names(WRAPPER_DEFAULT_CLASSES)
      @system_arguments[:id] = @id
      @body_arguments[:tag] = BODY_TAG_DEFAULT
      @body_arguments[:classes] = class_names(BODY_DEFAULT_CLASSES)
      @body_arguments[:role] = 'tablist'
      @body_arguments[:'aria-label'] = label
    end

    # def before_render
    #   # Eagerly evaluate content to avoid https://github.com/primer/view_components/issues/1790
    #   content

    #   super
    # end
  end
end
