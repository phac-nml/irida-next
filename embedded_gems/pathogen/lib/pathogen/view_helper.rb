# frozen_string_literal: true

module Pathogen
  # ViewHelper for pathogen component helpers
  module ViewHelper
    PATHOGEN_COMPONENT_HELPERS = {
      button: 'Pathogen::Button',
      datepicker: 'Pathogen::Datepicker',
      icon: 'Pathogen::Icon',
      link: 'Pathogen::Link',
      radio_button: 'Pathogen::Form::RadioButton',
      heading: 'Pathogen::Typography::Heading',
      heading_group: 'Pathogen::Typography::HeadingGroup',
      section: 'Pathogen::Typography::Section',
      text: 'Pathogen::Typography::Text',
      supporting: 'Pathogen::Typography::Supporting',
      lead: 'Pathogen::Typography::Lead',
      callout: 'Pathogen::Typography::Callout',
      eyebrow: 'Pathogen::Typography::Eyebrow',
      code: 'Pathogen::Typography::Code',
      code_block: 'Pathogen::Typography::CodeBlock',
      list: 'Pathogen::Typography::List'
    }.freeze

    # Define helper methods for components
    PATHOGEN_COMPONENT_HELPERS.each do |name, component|
      define_method "pathogen_#{name}" do |*args, **kwargs, &block|
        render component.constantize.new(*args, **kwargs), &block
      end
    end

    # Render typography with a preset configuration
    #
    # @param preset [Symbol] Preset name (:article, :card, :section, :dialog, :form_section)
    # @param overrides [Hash] Options to override preset defaults
    # @return [String] Rendered HeadingGroup component
    #
    # @example Article header
    #   <%= pathogen_typography_preset(:article) do |group| %>
    #     <%= group.with_eyebrow { "Blog Post" } %>
    #     <%= group.with_heading { "Introduction to Typography" } %>
    #     <%= group.with_metadata { "Published January 15, 2024" } %>
    #   <% end %>
    #
    # @example Card with overrides
    #   <%= pathogen_typography_preset(:card, heading_variant: :subdued) do |group| %>
    #     <%= group.with_heading { "Card Title" } %>
    #   <% end %>
    def pathogen_typography_preset(preset, **overrides, &)
      preset_config = Pathogen::Typography::Constants::PRESETS[preset]
      raise ArgumentError, "Unknown typography preset: #{preset}" unless preset_config

      # Merge preset config with overrides
      config = preset_config.merge(overrides)

      # Build HeadingGroup with preset configuration
      render(Pathogen::Typography::HeadingGroup.new(
               level: config[:heading_level],
               heading_variant: config[:heading_variant],
               responsive: config[:heading_responsive],
               spacing: config[:spacing]
             ), &)
    end
  end
end
