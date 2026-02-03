# frozen_string_literal: true

module Viral
  # 🚀 DropdownComponent: Professional, idiomatic dropdown for Viral UI
  #
  # Renders a dropdown menu with support for:
  #   - Custom label, icon, caret, and tooltip
  #   - Click or hover trigger
  #   - Action button mode
  #   - Accessibility (aria-label, aria-haspopup, etc.)
  #   - Custom styles and system arguments
  #
  # 📝 Usage:
  #   <%= render Viral::DropdownComponent.new(label: "Menu", icon: :dots, tooltip: "More actions") do |dropdown| %>
  #     <%= dropdown.item ... %>
  #   <% end %>
  #
  # 💡 All configuration is via keyword arguments. See initialize for details.
  # rubocop:disable Metrics/ClassLength
  class DropdownComponent < Viral::Component
    renders_many :items, Dropdown::ItemComponent

    # Public: Expose key dropdown configuration
    attr_reader :distance, :label, :icon_name, :caret, :skidding, :trigger, :tooltip_text, :styles, :prefix, :trigger_id

    TRIGGER_DEFAULT = :click
    TRIGGER_MAPPINGS = {
      click: 'click',
      hover: 'hover'
    }.freeze

    # 🏗️ Initialize a new DropdownComponent.
    #
    # @param label [String] Optional label for the button
    # @param tooltip [String] Optional tooltip for the button
    # @param icon [String] Optional icon name
    # @param caret [Boolean] Show dropdown caret icon
    # @param trigger [Symbol] :click or :hover (default :click)
    # @param skidding [Integer] Popper.js skidding offset
    # @param distance [Integer] Popper.js distance offset
    # @param styles [Hash] Custom styles for dropdown/button
    # @param action_link [Boolean] Use as action button
    # @param action_link_value [Object] Value for action button
    # @param system_arguments [Hash] Additional HTML/system args
    def initialize(**params)
      @params = params
      set_basic_attributes
      set_system_arguments
    end

    private

    # 🏷️ Set basic attributes from params
    def set_basic_attributes
      assign_display_attributes
      assign_tooltip_inputs
      assign_action_attributes
      assign_identity_attributes
    end

    def assign_display_attributes
      @distance = @params[:distance] || 10
      @styles = (@params[:styles] || {}).with_indifferent_access
      @label = @params[:label]
      @icon_name = @params[:icon]
      @caret = @params[:caret]
      @skidding = @params[:skidding] || 0
    end

    def assign_tooltip_inputs
      @tooltip_text = @params[:tooltip]
      @tooltip_placement = @params.fetch(:tooltip_placement, :top).to_sym
    end

    def assign_action_attributes
      @action_link = @params[:action_link]
      @action_link_value = @params[:action_link_value]
      @trigger = TRIGGER_MAPPINGS.fetch(
        @params[:trigger] || TRIGGER_DEFAULT,
        TRIGGER_MAPPINGS[TRIGGER_DEFAULT]
      )
    end

    def assign_identity_attributes
      @dd_id = "dd-#{SecureRandom.hex(10)}"
      @prefix = @params[:prefix]
      @trigger_id = @params[:trigger_id]
    end

    # 🛠️ Build and enhance system arguments for the dropdown trigger
    def set_system_arguments
      @system_arguments = build_system_arguments
      apply_tooltip_attributes
      add_button_styles
      add_icon_styles
      add_aria_label
      add_title_attribute
    end

    # 💬 Apply accessible tooltip wiring using Pathogen::Tooltip when tooltip text is present
    def apply_tooltip_attributes
      return unless tooltip?

      @tooltip_id ||= generate_tooltip_id
      @tooltip_placement ||= :top

      wire_tooltip_data_attributes
    end

    def generate_tooltip_id
      tooltip_id_from_trigger || Pathogen::Tooltip.generate_id(base_name: 'viral-dropdown-tooltip')
    end

    def wire_tooltip_data_attributes
      @system_arguments[:data] ||= {}
      @system_arguments[:aria] ||= {}

      @system_arguments[:data]['pathogen--tooltip-target'] ||= 'trigger'

      describedby = @system_arguments[:aria][:describedby]
      @system_arguments[:aria][:describedby] = append_to_aria_describedby(describedby, @tooltip_id)
    end

    # 📝 Add title attribute from system arguments if present
    def add_title_attribute
      return if @system_arguments[:title].present?

      # Prefer explicit title, otherwise fall back to tooltip text for system preview expectations
      @system_arguments[:title] = @params[:title].presence || tooltip_text
    end

    # 🎨 Add button styles, using custom or default
    def add_button_styles
      return if @label.blank?

      if @styles[:button].present?
        @system_arguments[:classes] = @styles[:button]
      else
        @system_arguments.merge!(system_arguments_for_button)
      end
    end

    # 🖼️ Add icon styles if icon is present
    def add_icon_styles
      return if @icon_name.blank?

      @system_arguments.merge!(system_arguments_for_icon)
    end

    # ♿️ Ensure accessible labeling for the dropdown trigger
    # Priority:
    #   1. aria.label param
    #   2. system_arguments['aria-label']
    #   3. label (visible)
    #   4. tooltip
    #   5. icon-only: must have aria-label
    #   6. fallback: icon name or 'Menu'
    def add_aria_label
      if aria_label_from_params
        @system_arguments['aria-label'] = aria_label_from_params
        return
      end
      return if @system_arguments['aria-label'].present?
      return if @label.present?

      if tooltip_aria_label
        @system_arguments['aria-label'] = tooltip_aria_label
        return
      end
      ensure_icon_only_has_aria_label
      @system_arguments['aria-label'] ||= default_aria_label
    end

    # 🔍 Extract aria-label from params
    def aria_label_from_params
      @params.dig(:aria, :label)
    end

    def tooltip?
      tooltip_text.present?
    end

    def tooltip_component
      return unless tooltip?

      Pathogen::Tooltip.new(
        text: tooltip_text,
        id: @tooltip_id,
        placement: @tooltip_placement
      )
    end

    # 🔍 Extract tooltip for aria-label
    def tooltip_aria_label
      @params[:tooltip].presence
    end

    # ⚠️ Raise if icon-only button is missing aria-label
    def ensure_icon_only_has_aria_label
      return unless @icon_name.present? && @label.blank? && @system_arguments['aria-label'].blank?

      raise ArgumentError, "Icon-only buttons must have an aria-label, icon: #{@icon_name}"
    end

    # 🏷️ Fallback aria-label
    def default_aria_label
      return "#{@icon_name.to_s.humanize} menu" if @icon_name.present?

      'Menu'
    end

    # 🏗️ Build system arguments for the dropdown trigger
    #
    # Uses deep_merge to combine base dropdown arguments with custom system_arguments.
    # This allows composing the dropdown with other Stimulus controllers (e.g., tooltips)
    # while preserving the dropdown's core functionality.
    #
    # Example:
    #   system_arguments: {
    #     data: { 'pathogen--tooltip-target': 'trigger' },  # Preserves viral--dropdown-target
    #     aria: { describedby: 'tooltip-id' }               # Preserves aria-expanded, aria-haspopup
    #   }
    def build_system_arguments
      data = build_data_attributes
      base_args = {
        id: trigger_id || "dd-#{SecureRandom.hex(10)}",
        data: data,
        tag: :button,
        type: :button,
        classes: 'cursor-pointer px-4 py-2 w-full',
        'aria-expanded': false,
        'aria-haspopup': true,
        'aria-controls': @dd_id
      }
      system_args = @params[:system_arguments] || {}

      # Deep merge to preserve nested hash attributes (data, aria, etc.)
      base_args.deep_merge(system_args)
    end

    # 🏗️ Build data attributes for the dropdown trigger
    def build_data_attributes
      data = { 'viral--dropdown-target': 'trigger' }
      return data unless @action_link

      data.merge(
        turbo_stream: true,
        controller: 'action-button',
        action_link_required_value: @action_link_value
      )
    end

    # 🎨 Default system arguments for button
    def system_arguments_for_button
      return { classes: @styles[:button] } if @styles[:button].present?

      {
        classes: class_names(
          'button button-default',
          system_arguments[:classes]
        )
      }
    end

    # 🎨 Default system arguments for icon
    def system_arguments_for_icon
      return { classes: @styles[:button] } if @styles[:button].present?

      {
        classes: class_names('viral-dropdown--icon', @system_arguments[:classes])
      }
    end

    def tooltip_id_from_trigger
      return if trigger_id.blank?

      "#{trigger_id}-tooltip"
    end

    # Append an ID to a space-separated list of IDs for aria-describedby.
    # The aria-describedby attribute accepts multiple IDs separated by spaces,
    # so this builds that space-separated list correctly per ARIA spec.
    #
    # @param existing [String] Existing space-separated ID list (or nil)
    # @param id [String] New ID to append to the list
    # @return [String] Space-separated list of IDs
    def append_to_aria_describedby(existing, id)
      return id if existing.blank?

      ids = existing.to_s.split(/\s+/)
      return existing if ids.include?(id)

      "#{existing} #{id}"
    end
  end
  # rubocop:enable Metrics/ClassLength
end
