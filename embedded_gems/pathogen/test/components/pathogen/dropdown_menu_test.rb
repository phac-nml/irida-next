# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Test suite for Pathogen::DropdownMenu component
  class DropdownMenuTest < ViewComponent::TestCase
    test 'requires trigger slot' do
      error = assert_raises(ArgumentError) do
        render_inline(Pathogen::DropdownMenu.new) do |menu|
          menu.with_item(label: 'Edit', href: '#')
        end
      end

      assert_equal 'trigger slot is required', error.message
    end

    test 'requires at least one menu entry' do
      error = assert_raises(ArgumentError) do
        render_inline(Pathogen::DropdownMenu.new) do |menu|
          menu.with_trigger(aria_label: 'Open menu') { 'Open' }
        end
      end

      assert_equal 'at least one menu entry is required', error.message
    end

    test 'renders root controller data and menu wiring' do
      render_inline(Pathogen::DropdownMenu.new(offset: 12, auto_submit: true, submit_on_apply: true)) do |menu|
        menu.with_trigger(aria_label: 'Open menu') { 'Open' }
        menu.with_item(label: 'Edit', href: '#')
      end

      assert_selector '[data-controller="pathogen--dropdown-menu"]'
      assert_selector '[data-pathogen--dropdown-menu-placement-value]'
      assert_selector '[data-pathogen--dropdown-menu-offset-value="12"]'
      assert_selector '[data-pathogen--dropdown-menu-auto-submit-value="true"]'
      assert_selector '[data-pathogen--dropdown-menu-submit-on-apply-value="true"]'

      assert_selector 'button[aria-haspopup="menu"][aria-expanded="false"][aria-controls]'
      assert_selector 'div[role="menu"][hidden][tabindex="-1"][aria-labelledby]', visible: :all
    end

    test 'renders checkbox item with hidden input and aria-checked' do
      render_inline(Pathogen::DropdownMenu.new) do |menu|
        menu.with_trigger(aria_label: 'Open menu') { 'Open' }
        menu.with_checkbox_item(label: 'Archived', name: 'filters[]', value: 'archived', checked: true)
      end

      input = page.find(
        'input[type="checkbox"][data-pathogen--dropdown-menu-target="input"][name="filters[]"][value="archived"]',
        visible: :all
      )
      assert input[:checked].present?
      assert_selector(
        'button[role="menuitemcheckbox"][aria-checked="true"][data-name="filters[]"][data-value="archived"]',
        visible: :all
      )
    end

    test 'renders footer apply/cancel actions with common translations by default' do
      render_inline(Pathogen::DropdownMenu.new) do |menu|
        menu.with_trigger(aria_label: 'Open menu') { 'Open' }
        menu.with_checkbox_item(label: 'Archived', name: 'filters[]', value: 'archived')
        menu.with_apply_action
        menu.with_cancel_action
      end

      assert_selector 'button', text: I18n.t('common.actions.cancel'), visible: :all
      assert_selector 'button', text: I18n.t('common.actions.apply'), visible: :all
    end

    test 'renders one-level submenu with nested menu region' do
      render_inline(Pathogen::DropdownMenu.new) do |menu|
        menu.with_trigger(aria_label: 'Open menu') { 'Open' }
        menu.with_submenu(label: 'More') do |submenu|
          submenu.with_item(label: 'Rename', href: '#')
        end
      end

      assert_selector 'button[data-submenu-trigger="true"][aria-haspopup="menu"][aria-controls]', visible: :all
      assert_selector 'div[role="menu"][hidden][data-submenu="true"]', visible: :all
      assert_selector 'div[role="menu"][data-submenu="true"]', text: 'Rename', visible: :all
    end
  end
end
