# frozen_string_literal: true

require 'application_system_test_case'

module Admin
  class SiteBannersTest < ApplicationSystemTestCase
    setup do
      login_as users(:system_user)
    end

    test 'disable action opens a confirmation dialog' do
      banner = SiteBanner.create!(
        style: :info,
        messages: I18n.available_locales.index_with { |_locale| 'Maintenance notice' }
      )

      visit admin_site_banner_path(banner)

      dismiss_confirm(I18n.t('active_admin.site_banners.disable_confirm')) do
        click_link I18n.t('active_admin.site_banners.disable')
      end
    end

    test 'enabled checkbox can be toggled on the new form' do
      visit new_admin_site_banner_path

      checkbox = find('#site_banner_enabled')
      assert checkbox.checked?

      checked_styles = page.evaluate_script(<<~JS)
        (() => {
          const style = getComputedStyle(document.querySelector('#site_banner_enabled'));
          return { bg: style.backgroundColor, image: style.backgroundImage };
        })()
      JS
      assert_not_equal 'none', checked_styles['image']

      uncheck I18n.t('activerecord.attributes.site_banner.enabled')

      unchecked_styles = page.evaluate_script(<<~JS)
        (() => {
          const el = document.querySelector('#site_banner_enabled');
          const style = getComputedStyle(el);
          return { bg: style.backgroundColor, image: style.backgroundImage, checked: el.checked };
        })()
      JS
      assert_not unchecked_styles['checked']
      assert_equal 'none', unchecked_styles['image']
      assert_not_equal checked_styles['bg'], unchecked_styles['bg']
    end
  end
end
