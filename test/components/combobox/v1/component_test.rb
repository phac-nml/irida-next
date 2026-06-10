# frozen_string_literal: true

require 'application_system_test_case'

module Combobox
  module V1
    class ComponentTest < ApplicationSystemTestCase
      def test_accessibility_states
        visit('/rails/view_components/combobox_component/default')
        within "div[data-controller='combobox--v1']" do
          assert_accessible

          combobox = find("input[role='combobox']")
          combobox.click
          assert_accessible

          combobox.send_keys('this does not exist')
          assert_selector "div[role='status']", text: I18n.t('combobox_component.no_results_text')
          assert_accessible
        end

        visit('/rails/view_components/combobox_component/disabled')
        within "div[data-controller='combobox--v1']" do
          assert_accessible
        end
      end

      def test_default # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        visit('/rails/view_components/combobox_component/default')
        within "div[data-controller='combobox--v1']" do
          combobox = find("input[role='combobox']")
          assert_equal 'age', combobox.value
          assert_equal 'false', combobox['aria-expanded']
          assert_no_selector 'svg.caret-down-icon.rotate-180'
          assert_selector 'svg.caret-down-icon'
          combobox.click
          assert_equal 'true', combobox['aria-expanded']
          assert_selector 'svg.caret-down-icon.rotate-180'
          listbox = find("div[role='listbox']")
          within listbox do
            group = find("div[role='group']")
            within group do
              assert_selector "div[role='presentation']", text: 'Metadata fields'
              assert_selector "div[role='option'][data-value='metadata.age']"
              assert_selector "div[role='option'][data-value='metadata.patient_age']"
              find("div[role='option'][data-value='metadata.patient_age']").click
              assert_equal 'patient_age', combobox.value
            end
          end
          hidden = find("input[type='hidden']", visible: false)
          assert_equal 'metadata.patient_age', hidden.value
          assert_no_selector 'svg.caret-down-icon.rotate-180'
          assert_selector 'svg.caret-down-icon'
        end
      end

      def test_no_results_found
        visit('/rails/view_components/combobox_component/default')
        within "div[data-controller='combobox--v1']" do
          combobox = find("input[role='combobox']")
          combobox.send_keys('this does not exist')
          assert_selector "div[role='status']", text: I18n.t('combobox_component.no_results_text')
        end
      end

      def test_enter_key
        visit('/rails/view_components/combobox_component/default')
        within "div[data-controller='combobox--v1']" do
          combobox = find("input[role='combobox']")
          combobox.send_keys(:down, :down, :enter)
          assert_selector "div[role='listbox']", visible: false
          assert_equal 'patient_age', combobox.value
          hidden = find("input[type='hidden']", visible: false)
          assert_equal 'metadata.patient_age', hidden.value
          combobox.click
          assert_selector "div[role='listbox']", visible: true
          assert_selector "div[role='option'][data-value='metadata.patient_age']", count: 1
        end
      end

      def test_alt_and_down_combination_keys
        visit('/rails/view_components/combobox_component/default')
        within "div[data-controller='combobox--v1']" do
          combobox = find("input[role='combobox']")
          combobox.send_keys(%i[alt down])
          assert_selector "div[role='listbox']", visible: true
          first_option = all("div[role='option']")[0]
          assert_nil first_option['aria-selected']
        end
      end

      def test_down_and_up_keys
        visit('/rails/view_components/combobox_component/default')
        within "div[data-controller='combobox--v1']" do
          combobox = find("input[role='combobox']")
          combobox.send_keys(:down, :down, :down)
          options = all("div[role='option']")
          first_option = options.first
          assert_equal first_option[:id], combobox['aria-activedescendant']
          combobox.send_keys(:up)
          last_option = options.last
          assert_equal last_option[:id], combobox['aria-activedescendant']
        end
      end

      def test_right_and_left_keys
        visit('/rails/view_components/combobox_component/default')
        within "div[data-controller='combobox--v1']" do
          combobox = find("input[role='combobox']")
          combobox.click.send_keys(:left, :left, :right)
          cursor_position = page.evaluate_script("document.getElementById('field').selectionStart")
          assert_equal 2, cursor_position
        end
      end

      def test_home_and_end_keys # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        visit('/rails/view_components/combobox_component/default')
        within "div[data-controller='combobox--v1']" do
          combobox = find("input[role='combobox']")
          combobox.click.send_keys(:escape, :home)
          cursor_position = page.evaluate_script("document.getElementById('field').selectionStart")
          assert_equal 0, cursor_position

          combobox.send_keys(:end)
          cursor_position = page.evaluate_script("document.getElementById('field').selectionStart")
          assert_equal 3, cursor_position

          combobox.send_keys(%i[alt down])
          combobox.send_keys(:end)
          options = all("div[role='option']")
          last_option = options.last
          assert_equal last_option[:id], combobox['aria-activedescendant']

          combobox.send_keys(:home)
          first_option = options.first
          assert_equal first_option[:id], combobox['aria-activedescendant']
        end
      end

      def test_disabled_option_is_not_selectable
        visit('/rails/view_components/combobox_component/with_disabled_options')
        within "div[data-controller='combobox--v1']" do
          combobox = find("input[role='combobox']")
          combobox.click

          assert_selector "div[role='option'][data-value='disabled-option'][aria-disabled='true']"
          assert_empty combobox.value
          assert_empty find("input[type='hidden']", visible: false).value

          find("div[role='option'][data-value='enabled-option']").click
          assert_equal 'Enabled option', combobox.value
          assert_equal 'enabled-option', find("input[type='hidden']", visible: false).value
        end
      end

      def test_escape_key
        visit('/rails/view_components/combobox_component/default')
        within "div[data-controller='combobox--v1']" do
          combobox = find("input[role='combobox']")
          combobox.click
          listbox = find("div[role='listbox']")
          assert_matches_style(listbox, 'display' => 'block')
          assert_equal 'age', combobox.value
          combobox.send_keys(:escape, :escape)
          assert_matches_style(listbox, 'display' => 'none')
          assert_empty combobox.value
          hidden = find("input[type='hidden']", visible: false)
          assert_empty hidden.value
        end
      end

      def test_disabled_combobox_does_not_open_or_change # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
        visit('/rails/view_components/combobox_component/disabled')
        within "div[data-controller='combobox--v1']" do
          combobox = find("input[role='combobox']")
          hidden = find("input[type='hidden']", visible: false)

          assert_equal 'age', combobox.value
          assert_equal 'metadata.age', hidden.value
          assert_equal 'true', combobox['aria-disabled']
          assert_equal 'readonly', combobox['readonly']

          beforeinput_prevented = page.evaluate_script(<<~JS)
            (() => {
              const combobox = document.querySelector('input[role="combobox"]');
              return !combobox.dispatchEvent(new InputEvent('beforeinput', {
                bubbles: true,
                cancelable: true,
                data: 'country',
                inputType: 'insertText',
              }));
            })();
          JS
          assert beforeinput_prevented

          page.execute_script(<<~JS)
            const combobox = document.querySelector('input[role="combobox"]');
            combobox.dispatchEvent(new MouseEvent('click', { bubbles: true }));
            combobox.dispatchEvent(
              new KeyboardEvent('keydown', { key: 'ArrowDown', bubbles: true })
            );
            combobox.dispatchEvent(new KeyboardEvent('keyup', { key: 'c', bubbles: true }));
            combobox.dispatchEvent(new KeyboardEvent('keydown', { key: 'Enter', bubbles: true }));
          JS

          assert_equal 'age', combobox.value
          assert_equal 'metadata.age', hidden.value
          assert_equal 'false', combobox['aria-expanded']
          assert_selector "div[role='listbox']", visible: false
        end
      end
    end
  end
end
