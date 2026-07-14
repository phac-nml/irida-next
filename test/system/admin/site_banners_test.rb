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
  end
end
