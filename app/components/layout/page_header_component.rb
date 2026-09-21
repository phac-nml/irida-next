# frozen_string_literal: true

module Layout
  # Shared page header structure for IRIDA Next views.
  #
  # This component intentionally preserves the existing PageHeader slot API used
  # throughout the app (`icon`, `with_buttons`) so callsites can migrate away
  # from Viral namespace without layout changes.
  class PageHeaderComponent < Component
    attr_reader :title, :subtitle, :id, :id_color

    renders_one :icon
    renders_one :buttons

    def initialize(title:, id: nil, subtitle: nil, id_color: :primary)
      @title = title
      @id = id
      @subtitle = subtitle
      @id_color = id_color
    end
  end
end
