# frozen_string_literal: true

module Pathogen
  # Dropdown Menu Component
  #
  # Accessible dropdown menu following the WAI-ARIA menu button pattern.
  #
  # This component is progressively enhanced via a Stimulus controller in the host app:
  # - app/javascript/controllers/pathogen/dropdown_menu_controller.js
  #
  # Positioning is handled with Floating UI (@floating-ui/dom).
  #
  # Keyboard support (when JS is enabled):
  # - Trigger: Enter/Space/ArrowDown opens and focuses first item, ArrowUp opens last item
  # - Menu: ArrowUp/ArrowDown, Home/End, Enter/Space activates, Esc cancels (revert + close)
  # - Outside click cancels (revert + close)
  # - Submenu (one level): ArrowRight opens, ArrowLeft closes; hover opens
  #
  # Events (from the Stimulus controller):
  # - pathogen:dropdown-menu:change
  #   - Fired for checkbox toggles (source: "toggle"), apply ("apply"), and single-select ("single")
  # - pathogen:dropdown-menu:cancel
  #   - Fired when the menu is dismissed (source: "cancel"|"escape"|"outside")
  #
  # == Recommended usage (trigger slot only)
  #
  # Render the dropdown and provide a trigger slot that renders the button UI.
  # Inside the menu, add normal items for navigation/actions and checkbox items for multi-select.
  # Each checkbox item should provide a name/value (and checked state) so it can integrate cleanly
  # with forms and event payloads.
  #
  # For multi-select, provide Apply/Cancel footer actions:
  # - Apply confirms the current selection and emits a single change event containing the full values array.
  # - Cancel (and Escape/outside click) reverts selection to what it was when the menu opened and emits a cancel event.
  #
  # For single-select, enable auto_submit to dispatch a change event and then requestSubmit() the nearest form.
  #
  # @example Multi-select in a form (recommended)
  #   <%= form_with url: search_path, method: :get do %>
  #     <%= render(Pathogen::DropdownMenu.new(auto_submit: false, submit_on_apply: true)) do |menu| %>
  #       <% menu.with_trigger(aria_label: "Filters") do %>
  #         <span class="inline-flex items-center gap-2">
  #           <%= pathogen_icon(:funnel, size: :sm) %>
  #           <span>Filters</span>
  #         </span>
  #       <% end %>
  #
  #       <% menu.with_checkbox_item(label: "Archived", name: "filters[]", value: "archived", checked: false) %>
  #       <% menu.with_checkbox_item(label: "Owned by me", name: "filters[]", value: "mine", checked: true) %>
  #
  #       <% menu.with_apply_action %>
  #       <% menu.with_cancel_action %>
  #     <% end %>
  #   <% end %>
  class DropdownMenu < Pathogen::Component # rubocop:disable Metrics/ClassLength
    PLACEMENT_OPTIONS = %i[
      bottom_start
      bottom_end
      top_start
      top_end
      right_start
      right_end
      left_start
      left_end
    ].freeze

    PLACEMENT_MAPPINGS = {
      bottom_start: 'bottom-start',
      bottom_end: 'bottom-end',
      top_start: 'top-start',
      top_end: 'top-end',
      right_start: 'right-start',
      right_end: 'right-end',
      left_start: 'left-start',
      left_end: 'left-end'
    }.freeze

    DEFAULT_PLACEMENT = :bottom_start

    renders_one :trigger, lambda { |aria_label: nil, **system_arguments, &block|
      Pathogen::DropdownMenu::Trigger.new(
        id: @trigger_id,
        menu_id: @menu_id,
        aria_label: aria_label,
        **system_arguments,
        &block
      )
    }

    # rubocop:disable Metrics/ParameterLists, Metrics/AbcSize, Metrics/MethodLength
    def initialize(id: nil, placement: DEFAULT_PLACEMENT, offset: 8, auto_submit: false, submit_on_apply: false,
                   **system_arguments)
      # rubocop:enable Metrics/ParameterLists, Metrics/AbcSize, Metrics/MethodLength
      @id = id.presence || self.class.generate_id(base_name: 'dropdown-menu')
      @trigger_id = "#{@id}-trigger"
      @menu_id = "#{@id}-menu"

      @placement = fetch_or_fallback(PLACEMENT_OPTIONS, placement, DEFAULT_PLACEMENT)
      @offset = offset
      @auto_submit = auto_submit
      @submit_on_apply = submit_on_apply

      @system_arguments = system_arguments
      @entries = []

      @system_arguments[:id] ||= @id
      @system_arguments[:data] ||= {}
      @system_arguments[:data][:controller] = 'pathogen--dropdown-menu'
      @system_arguments[:data]['pathogen--dropdown-menu-placement-value'] = PLACEMENT_MAPPINGS[@placement]
      @system_arguments[:data]['pathogen--dropdown-menu-offset-value'] = @offset
      @system_arguments[:data]['pathogen--dropdown-menu-auto-submit-value'] = @auto_submit
      @system_arguments[:data]['pathogen--dropdown-menu-submit-on-apply-value'] = @submit_on_apply
      @system_arguments[:class] = class_names('relative inline-block', @system_arguments[:class])
    end

    def with_item(label:, href: nil, disabled: false, destructive: false, **system_arguments)
      @entries << Pathogen::DropdownMenu::Item.new(
        label: label,
        href: href,
        disabled: disabled,
        destructive: destructive,
        **system_arguments
      )
    end

    def with_checkbox_item(label:, name:, value:, **system_arguments)
      @entries << Pathogen::DropdownMenu::CheckboxItem.new(
        label: label,
        name: name,
        value: value,
        **system_arguments
      )
    end

    def with_radio_item(label:, name:, value:, **system_arguments)
      @entries << Pathogen::DropdownMenu::RadioItem.new(
        label: label,
        name: name,
        value: value,
        **system_arguments
      )
    end

    def with_label(text:, **system_arguments)
      @entries << Pathogen::DropdownMenu::Label.new(text: text, **system_arguments)
    end

    def with_separator(**system_arguments)
      @entries << Pathogen::DropdownMenu::Separator.new(**system_arguments)
    end

    def with_submenu(label:, disabled: false, destructive: false, **system_arguments)
      submenu = Pathogen::DropdownMenu::Submenu.new(
        parent_menu_id: @menu_id,
        label: label,
        disabled: disabled,
        destructive: destructive,
        **system_arguments
      )
      yield submenu if block_given?
      @entries << submenu
    end

    def with_apply_action(label: nil, **system_arguments)
      @apply_action = Pathogen::DropdownMenu::FooterAction.new(
        kind: :apply,
        label: label.presence || t('common.actions.apply'),
        **system_arguments
      )
    end

    def with_cancel_action(label: nil, **system_arguments)
      @cancel_action = Pathogen::DropdownMenu::FooterAction.new(
        kind: :cancel,
        label: label.presence || t('common.actions.cancel'),
        **system_arguments
      )
    end

    attr_reader :entries, :apply_action, :cancel_action

    def footer?
      @apply_action.present? || @cancel_action.present?
    end

    def before_render
      raise ArgumentError, 'trigger slot is required' unless trigger
      raise ArgumentError, 'at least one menu entry is required' if @entries.empty?
    end
  end
end
