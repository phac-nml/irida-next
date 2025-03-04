# frozen_string_literal: true

module Viral
  # Card component for rendering sections of pages.
  class CardComponent < Viral::Component
    attr_reader :sectioned, :subtitle, :title, :title_id

    renders_one :header, Viral::Card::HeaderComponent
    renders_many :sections, Viral::Card::SectionComponent

    def initialize(title: nil, title_id: nil, subtitle: nil, sectioned: true, **system_arguments)
      @title = title
      @title_id = title_id
      @subtitle = subtitle
      @sectioned = sectioned
      @system_arguments = system_arguments
    end

    def system_arguments
      @system_arguments[:tag] = 'section'
      @system_arguments[:classes] = class_names(
        @system_arguments[:classes],
        'viral-card bg-white border border-slate-200 rounded-md shadow-sm dark:border-slate-700 dark:bg-slate-800'
      )
      @system_arguments
    end
  end
end
