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
  #   <%= render Viral::DropdownComponent.new(label: "Menu", icon: "dots", tooltip: "More actions") do |dropdown| %>
  #     <%= dropdown.item ... %>
  #   <% end %>
  #
  # 💡 All configuration is via keyword arguments. See initialize for details.
  # rubocop:disable Metrics/ClassLength
  class DropdownComponent < Viral::Component
    renders_many :items, Dropdown::ItemComponent

    # Public: Expose key dropdown configuration
    attr_reader :distance, :label, :icon_name, :caret, :skidding, :trigger, :tooltip, :styles, :prefix

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
      @distance = @params[:distance] || 10
      @styles = (@params[:styles] || {}).with_indifferent_access
      @label = @params[:label]
      @icon_name = @params[:icon]
      @caret = @params[:caret]
      @skidding = @params[:skidding] || 0
      @action_link = @params[:action_link]
      @action_link_value = @params[:action_link_value]
      @trigger = TRIGGER_MAPPINGS.fetch(
        @params[:trigger] || TRIGGER_DEFAULT,
        TRIGGER_MAPPINGS[TRIGGER_DEFAULT]
      )
      @dd_id = "dd-#{SecureRandom.hex(10)}"
      @prefix = @params[:prefix]
    end

    # 🛠️ Build and enhance system arguments for the dropdown trigger
    def set_system_arguments
      @system_arguments = build_system_arguments
      add_tooltip
      add_button_styles
      add_icon_styles
      add_aria_label
      add_title_attribute
    end

    # 💬 Add tooltip as title attribute if present
    def add_tooltip
      return if @params[:tooltip].blank?

      @system_arguments[:title] = @params[:tooltip]
    end

    # 📝 Add title attribute from system arguments if present
    def add_title_attribute
      return if @system_arguments[:title].present?

      @system_arguments[:title] = @params[:title] if @params[:title].present?
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
    def build_system_arguments
      data = build_data_attributes
      {
        id: "dd-#{SecureRandom.hex(10)}",
        data: data,
        tag: :button,
        type: :button,
        classes: 'cursor-pointer',
        'aria-expanded': false,
        'aria-haspopup': true,
        'aria-controls': @dd_id
      }.merge(@params[:system_arguments] || {})
    end

    # 🏗️ Build data attributes for the dropdown trigger
    def build_data_attributes
      data = { 'viral--dropdown-target': 'trigger' }
      return data unless @action_link

      data.merge(
        action: 'turbo:morph-element->action-button#idempotentConnect',
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
  end
  # rubocop:enable Metrics/ClassLength
end
