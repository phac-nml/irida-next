# frozen_string_literal: true

require 'application_system_test_case'

module Projects
  class SettingsTest < ApplicationSystemTestCase
    # Resolves any CSS colour to sRGB through a canvas, then returns the WCAG
    # contrast ratio between an element's border and the surface behind it.
    BORDER_CONTRAST_JS = <<~JS
      (selector) => {
        const context = document.createElement("canvas").getContext("2d", { willReadFrequently: true });
        const rgb = (colour) => {
          context.clearRect(0, 0, 1, 1);
          context.fillStyle = colour;
          context.fillRect(0, 0, 1, 1);
          return Array.from(context.getImageData(0, 0, 1, 1).data).slice(0, 3);
        };
        const luminance = (channels) => {
          const [r, g, b] = channels.map((value) => {
            const channel = value / 255;
            return channel <= 0.04045 ? channel / 12.92 : ((channel + 0.055) / 1.055) ** 2.4;
          });
          return 0.2126 * r + 0.7152 * g + 0.0722 * b;
        };
        const surface = (element) => {
          for (let node = element.parentElement; node; node = node.parentElement) {
            const colour = getComputedStyle(node).backgroundColor;
            if (!["transparent", "rgba(0, 0, 0, 0)"].includes(colour)) return colour;
          }
          return "#ffffff";
        };
        const element = document.querySelector(selector);
        const border = luminance(rgb(getComputedStyle(element).borderTopColor));
        const background = luminance(rgb(surface(element)));
        return (Math.max(border, background) + 0.05) / (Math.min(border, background) + 0.05);
      }
    JS

    setup do
      @user = users(:john_doe)
      @project = projects(:project1)
      login_as @user
      visit namespace_project_edit_path(@project.namespace.parent, @project)
      assert_selector 'h1', text: I18n.t('projects.edit.general.title')
    end

    test 'settings page is accessible in light and dark themes' do
      assert_accessible

      use_dark_theme
      assert_accessible
    end

    test 'heading structure and landmarks are named' do
      assert_equal %w[H1 H2 H2 H2 H3 H3], page.all('main :is(h1, h2, h3)').map(&:tag_name).map(&:upcase)
      assert_selector 'section[aria-labelledby="project-settings-details"]'
      assert_selector 'section[aria-labelledby="project-settings-url"]'
      assert_selector 'section[aria-labelledby="project-settings-danger"]'
    end

    test 'form controls meet non-text contrast in light and dark themes' do
      assert_control_contrast

      use_dark_theme
      assert_control_contrast
    end

    test 'text fields use their visible labels as accessible names' do
      assert_field 'Name'
      assert_field 'Description'
      assert_no_selector 'textarea[aria-label]'
    end

    test 'path preview updates and stays linked to the field' do
      field = find_field(path_label)
      preview_id = "#{field[:id]}-preview".sub('_path-preview', '_path_preview')

      assert_includes field['aria-describedby'], preview_id

      field.fill_in with: 'renamed-path'

      within "##{preview_id}" do
        assert_selector 'strong', text: 'renamed-path'
      end
    end

    test 'invalid path is announced, described and accessible' do
      find_field(path_label).fill_in with: 'a'
      click_on I18n.t('projects.edit.advanced.path.submit')

      assert_selector 'turbo-frame#project_path_form input[aria-invalid="true"]'
      field = find('turbo-frame#project_path_form input[aria-invalid="true"]')
      assert_includes field['aria-describedby'], 'error'
      assert_accessible

      use_dark_theme
      assert_accessible
    end

    test 'path preview reconnects after a turbo stream update' do
      find_field(path_label).fill_in with: 'a'
      click_on I18n.t('projects.edit.advanced.path.submit')
      assert_selector 'turbo-frame#project_path_form input[aria-invalid="true"]'

      find_field(path_label).fill_in with: 'valid-path'

      assert_selector '[data-projects--path-preview-target="path"]', text: 'valid-path'
    end

    test 'delete confirmation is keyboard operable and accessible' do
      button = find_button(I18n.t('projects.edit.advanced.destroy.submit'))
      button.send_keys(:enter)

      within '#turbo-confirm' do
        assert_text @project.name
        assert_accessible

        send_keys :escape
      end

      assert_no_selector '#turbo-confirm[open]'
      assert_equal 1, Project.where(id: @project.id).count
    end

    test 'transfer confirmation shows the warning from the page' do
      within '#edit_advanced_transfer' do
        find_field(I18n.t('projects.edit.advanced.transfer.new_namespace_id')).click
        find('li[data-label]', match: :first).click
        assert_selector 'button[type=submit]:not(:disabled)'
        click_on I18n.t('projects.edit.advanced.transfer.submit')
      end

      within '#turbo-confirm' do
        assert_text @project.human_name
        assert_accessible
      end
    end

    test 'page reflows at 320 CSS pixels without horizontal scrolling' do
      page.current_window.resize_to(320, 800)

      overflow = page.evaluate_script(
        'document.documentElement.scrollWidth - document.documentElement.clientWidth'
      )

      assert_operator overflow, :<=, 0
      assert_accessible
    end

    test 'buttons meet the 44 CSS pixel target' do
      [
        I18n.t('projects.edit.general.submit'),
        I18n.t('projects.edit.advanced.path.submit'),
        I18n.t('projects.edit.advanced.destroy.submit')
      ].each do |label|
        height = find_button(label).evaluate_script('this.getBoundingClientRect().height')

        assert_operator height, :>=, 44, "#{label} is #{height}px tall"
      end
    end

    private

    def path_label
      I18n.t('activerecord.attributes.namespaces/project_namespace.path')
    end

    def use_dark_theme
      page.execute_script(<<~JS)
        document.documentElement.classList.remove('light');
        document.documentElement.classList.add('dark');
      JS
    end

    def assert_control_contrast
      ['main input[type="text"]', 'main textarea'].each do |selector|
        ratio = page.driver.with_playwright_page { |playwright| playwright.evaluate(BORDER_CONTRAST_JS, arg: selector) }

        assert_operator ratio, :>=, 3, "#{selector} border contrast is #{ratio.round(2)}:1"
      end
    end
  end
end
