# frozen_string_literal: true

module Pathogen
  # Lookbook preview for Pathogen::DialogComponent
  # Demonstrates various dialog configurations and use cases
  class DialogComponentPreview < ViewComponent::Preview
    # @!group Basic Examples

    # Default dialog with medium size and dismissible mode
    #
    # @label Default Dialog
    def default
      render(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_header { tag.h2 'Dialog Title', class: 'text-lg font-semibold' }
        dialog.with_body do
          tag.div do
            tag.p(
              'This is a basic dialog with default settings. It uses medium size and is dismissible via the close button, ESC key, or clicking the backdrop.', class: 'mb-4'
            ) +
              tag.p('The dialog component provides a clean, accessible way to display modal content.')
          end
        end
        dialog.with_footer do
          tag.button('Cancel', type: 'button',
                               class: 'px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-md hover:bg-slate-50') +
            tag.button('Confirm', type: 'button',
                                  class: 'ml-3 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700')
        end
      end
    end

    # @!endgroup

    # @!group Size Variants

    # Small dialog (max-w-md / 28rem)
    #
    # @label Small Dialog
    def small_dialog
      render(Pathogen::DialogComponent.new(size: :small)) do |dialog|
        dialog.with_header { tag.h2 'Small Dialog', class: 'text-lg font-semibold' }
        dialog.with_body do
          tag.p 'This is a small dialog, ideal for simple confirmations or brief messages.'
        end
        dialog.with_footer do
          tag.button('Close', type: 'button',
                              class: 'px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700')
        end
      end
    end

    # Large dialog (max-w-4xl / 56rem)
    #
    # @label Large Dialog
    def large_dialog
      render(Pathogen::DialogComponent.new(size: :large)) do |dialog|
        dialog.with_header { tag.h2 'Large Dialog', class: 'text-lg font-semibold' }
        dialog.with_body do
          tag.div do
            tag.p(
              'This is a large dialog, suitable for more complex content like forms with multiple fields or detailed information displays.', class: 'mb-4'
            ) +
              tag.p('The larger width provides more space for content while maintaining readability.')
          end
        end
        dialog.with_footer do
          tag.button('Cancel', type: 'button',
                               class: 'px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-md hover:bg-slate-50') +
            tag.button('Save', type: 'button',
                               class: 'ml-3 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700')
        end
      end
    end

    # Extra-large dialog (max-w-6xl / 72rem)
    #
    # @label Extra-Large Dialog
    def xlarge_dialog
      render(Pathogen::DialogComponent.new(size: :xlarge)) do |dialog|
        dialog.with_header { tag.h2 'Extra-Large Dialog', class: 'text-lg font-semibold' }
        dialog.with_body do
          tag.p 'This is an extra-large dialog, perfect for displaying extensive content, data tables, or complex multi-column layouts.'
        end
        dialog.with_footer do
          tag.button('Done', type: 'button',
                             class: 'px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700')
        end
      end
    end

    # @!endgroup

    # @!group Scrollable Content

    # Dialog with scrollable content and dynamic scroll shadows
    #
    # @label Scrollable Content
    def scrollable_content
      render(Pathogen::DialogComponent.new(size: :medium)) do |dialog|
        dialog.with_header { tag.h2 'Select Items', class: 'text-lg font-semibold' }
        dialog.with_body do
          tag.div do
            # Search input
            search_input = tag.input(type: 'search', placeholder: 'Search items...',
                                     class: 'w-full px-3 py-2 border border-slate-300 rounded-md mb-4')

            # Long list of items
            items_list = tag.div(class: 'space-y-2') do
              20.times.map do |i|
                tag.div(class: 'flex items-center p-3 border border-slate-200 rounded-md hover:bg-slate-50') do
                  tag.input(type: 'checkbox', id: "item-#{i}", class: 'mr-3') +
                    tag.label("Item #{i + 1} - This is a sample item with some description", for: "item-#{i}",
                                                                                             class: 'text-sm')
                end
              end.join.html_safe
            end

            search_input + items_list
          end
        end
        dialog.with_footer do
          tag.button('Cancel', type: 'button',
                               class: 'px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-md hover:bg-slate-50') +
            tag.button('Select', type: 'button',
                                 class: 'ml-3 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700')
        end
      end
    end

    # @!endgroup

    # @!group Dismissible Modes

    # Non-dismissible dialog for critical actions
    #
    # @label Non-Dismissible Dialog
    def non_dismissible
      render(Pathogen::DialogComponent.new(dismissible: false)) do |dialog|
        dialog.with_header { tag.h2 'Warning: Critical Action', class: 'text-lg font-semibold text-red-600' }
        dialog.with_body do
          tag.div do
            tag.p('This action cannot be undone. Please confirm that you want to proceed.',
                  class: 'mb-4 text-slate-700') +
              tag.p(
                'Note: This dialog cannot be dismissed by clicking outside or pressing ESC. You must click a button to proceed.', class: 'text-sm text-slate-500'
              )
          end
        end
        dialog.with_footer do
          tag.button('Cancel', type: 'button',
                               class: 'px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-md hover:bg-slate-50') +
            tag.button('Delete', type: 'button',
                                 class: 'ml-3 px-4 py-2 text-sm font-medium text-white bg-red-600 rounded-md hover:bg-red-700')
        end
      end
    end

    # @!endgroup

    # @!group Complex Content

    # Dialog with form inputs including selects and dropdowns
    #
    # @label Complex Form Dialog
    def complex_form
      render(Pathogen::DialogComponent.new(size: :large)) do |dialog|
        dialog.with_header { tag.h2 'Edit Profile', class: 'text-lg font-semibold' }
        dialog.with_body do
          tag.form(class: 'space-y-4') do
            # Name input
            name_field = tag.div(class: 'space-y-1') do
              tag.label('Name', for: 'name', class: 'block text-sm font-medium text-slate-700') +
                tag.input(type: 'text', id: 'name', value: 'John Doe',
                          class: 'w-full px-3 py-2 border border-slate-300 rounded-md')
            end

            # Email input
            email_field = tag.div(class: 'space-y-1') do
              tag.label('Email', for: 'email', class: 'block text-sm font-medium text-slate-700') +
                tag.input(type: 'email', id: 'email', value: 'john@example.com',
                          class: 'w-full px-3 py-2 border border-slate-300 rounded-md')
            end

            # Role select
            role_field = tag.div(class: 'space-y-1') do
              tag.label('Role', for: 'role', class: 'block text-sm font-medium text-slate-700') +
                tag.select(class: 'w-full px-3 py-2 border border-slate-300 rounded-md', id: 'role') do
                  tag.option('Admin', value: 'admin') +
                    tag.option('User', value: 'user', selected: true) +
                    tag.option('Guest', value: 'guest')
                end
            end

            # Department select
            dept_field = tag.div(class: 'space-y-1') do
              tag.label('Department', for: 'dept', class: 'block text-sm font-medium text-slate-700') +
                tag.select(class: 'w-full px-3 py-2 border border-slate-300 rounded-md', id: 'dept') do
                  %w[Engineering Marketing Sales Support].map do |dept|
                    tag.option(dept, value: dept.downcase)
                  end.join.html_safe
                end
            end

            name_field + email_field + role_field + dept_field
          end
        end
        dialog.with_footer do
          tag.button('Cancel', type: 'button',
                               class: 'px-4 py-2 text-sm font-medium text-slate-700 bg-white border border-slate-300 rounded-md hover:bg-slate-50') +
            tag.button('Save Changes', type: 'button',
                                       class: 'ml-3 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700')
        end
      end
    end

    # @!endgroup

    # @!group Without Footer

    # Dialog without footer slot (footer not rendered)
    #
    # @label No Footer
    def without_footer
      render(Pathogen::DialogComponent.new) do |dialog|
        dialog.with_header { tag.h2 'Information', class: 'text-lg font-semibold' }
        dialog.with_body do
          tag.p 'This dialog has no footer. The footer slot is optional and only renders when content is provided.'
        end
      end
    end

    # @!endgroup

    # @!group Show Button Slot

    # Dialog with integrated show button using the show_button slot
    # Demonstrates idiomatic Stimulus pattern with automatic data attribute wiring
    #
    # @label With Show Button
    def with_show_button
      render(Pathogen::DialogComponent.new(size: :medium)) do |dialog|
        dialog.with_show_button(scheme: :primary) { 'Open Dialog' }
        dialog.with_header { tag.h2 'Dialog with Show Button', class: 'text-lg font-semibold' }
        dialog.with_body do
          tag.div do
            tag.p(
              'This dialog uses the show_button slot, which automatically wires up the trigger button with the appropriate data attributes.', class: 'mb-4'
            ) +
              tag.p('Click the "Open Dialog" button above to see it in action!', class: 'text-sm text-slate-600')
          end
        end
        dialog.with_footer do
          tag.button('Close', type: 'button', data: { action: 'pathogen--dialog#close' },
                              class: 'px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700')
        end
      end
    end

    # Dialog with external trigger button using Stimulus action
    # Demonstrates manual trigger pattern for custom button placement
    #
    # @label With External Trigger
    def with_external_trigger
      tag.div do
        # External trigger button with Stimulus action
        trigger_button = tag.button('Open Dialog (External Trigger)',
                                    type: 'button',
                                    data: { action: 'click->pathogen--dialog#open' },
                                    class: 'mb-4 px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700')

        # Dialog definition
        dialog = render(Pathogen::DialogComponent.new(size: :medium)) do |d|
          d.with_header { tag.h2 'Externally Triggered Dialog', class: 'text-lg font-semibold' }
          d.with_body do
            tag.div do
              tag.p('This dialog is triggered by an external button that uses a Stimulus action.', class: 'mb-4') +
                tag.p(
                  'This pattern is useful when you need custom button placement or styling that differs from the dialog component.', class: 'text-sm text-slate-600'
                )
            end
          end
          d.with_footer do
            tag.button('Close', type: 'button', data: { action: 'pathogen--dialog#close' },
                                class: 'px-4 py-2 text-sm font-medium text-white bg-primary-600 rounded-md hover:bg-primary-700')
          end
        end

        trigger_button + dialog
      end
    end

    # Dialog with show button in different scheme colors
    # Demonstrates button customization options
    #
    # @label Button Schemes
    def button_schemes
      tag.div(class: 'space-y-4') do
        # Primary scheme
        primary = render(Pathogen::DialogComponent.new(size: :small)) do |dialog|
          dialog.with_show_button(scheme: :primary) { 'Primary Button' }
          dialog.with_header { tag.h2 'Primary Scheme', class: 'text-lg font-semibold' }
          dialog.with_body { tag.p 'Dialog opened with a primary scheme button.' }
        end

        # Default scheme
        default = render(Pathogen::DialogComponent.new(size: :small)) do |dialog|
          dialog.with_show_button(scheme: :default) { 'Default Button' }
          dialog.with_header { tag.h2 'Default Scheme', class: 'text-lg font-semibold' }
          dialog.with_body { tag.p 'Dialog opened with a default scheme button.' }
        end

        # Danger scheme
        danger = render(Pathogen::DialogComponent.new(size: :small)) do |dialog|
          dialog.with_show_button(scheme: :danger) { 'Danger Button' }
          dialog.with_header { tag.h2 'Danger Scheme', class: 'text-lg font-semibold' }
          dialog.with_body { tag.p 'Dialog opened with a danger scheme button.' }
        end

        primary + default + danger
      end
    end

    # @!endgroup
  end
end
