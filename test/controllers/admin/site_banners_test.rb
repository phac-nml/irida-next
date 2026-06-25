# frozen_string_literal: true

require 'test_helper'

module Admin
  class SiteBannersTest < ActionDispatch::IntegrationTest
    setup do
      sign_in users(:system_user)
    end

    test 'system user can view site banner index' do
      SiteBanner.create!(
        style: :info,
        messages: localized_messages('Maintenance notice')
      )

      get admin_site_banners_path

      assert_response :success
      assert_includes response.body, 'Maintenance notice'
      assert_includes response.body, I18n.t('active_admin.site_banners.disable')
      assert_includes response.body, disable_admin_site_banner_path(SiteBanner.current)
    end

    test 'system user sees translated French resource name' do
      users(:system_user).update!(locale: 'fr')

      get admin_site_banners_path

      assert_response :success
      assert_includes response.body, I18n.t('activerecord.models.site_banner.other', locale: :fr)
      assert_includes response.body, I18n.t('activerecord.attributes.site_banner.enabled', locale: :fr)
      assert_includes response.body, I18n.t('activerecord.attributes.site_banner.style', locale: :fr)
      assert_includes response.body, I18n.t('activerecord.attributes.site_banner.created_at', locale: :fr)
      assert_includes response.body, I18n.t('activerecord.attributes.site_banner.updated_at', locale: :fr)
      assert_not_includes response.body, 'Site Banners'
    end

    test 'system user can view new site banner form' do
      get new_admin_site_banner_path

      assert_response :success
      assert_includes response.body, 'site_banner_message_en'
      assert_includes response.body, 'site_banner_message_fr'
    end

    test 'system user can create a site banner' do
      assert_difference -> { SiteBanner.count }, 1 do
        post admin_site_banners_path, params: {
          site_banner: {
            enabled: '1',
            style: 'warning',
            messages: {
              en: 'Scheduled maintenance',
              fr: 'Maintenance planifiée'
            }
          }
        }
      end

      banner = SiteBanner.order(:created_at).last
      assert_redirected_to admin_site_banner_path(banner)
      assert banner.enabled?
      assert_equal 'warning', banner.style
      assert_equal 'Scheduled maintenance', banner.messages['en']
      assert_equal 'Maintenance planifiée', banner.messages['fr']
    end

    test 'system user can disable an enabled site banner' do
      banner = SiteBanner.create!(
        style: :danger,
        messages: localized_messages('Service outage')
      )

      patch disable_admin_site_banner_path(banner)

      assert_redirected_to admin_site_banner_path(banner)
      assert_not banner.reload.enabled?
    end

    test 'system user can view enable action for disabled site banner' do
      banner = SiteBanner.create!(
        enabled: false,
        style: :info,
        messages: localized_messages('Maintenance notice')
      )

      get admin_site_banners_path

      assert_response :success
      assert_includes response.body, I18n.t('active_admin.site_banners.enable')
      assert_includes response.body, enable_admin_site_banner_path(banner)
    end

    test 'system user sees enable action as a show page button' do
      banner = SiteBanner.create!(
        enabled: false,
        style: :info,
        messages: localized_messages('Maintenance notice')
      )

      get admin_site_banner_path(banner)

      assert_response :success
      assert_select "a.action-item-button[href='#{enable_admin_site_banner_path(banner)}']",
                    text: I18n.t('active_admin.site_banners.enable')
    end

    test 'system user can enable a disabled site banner' do
      banner = SiteBanner.create!(
        enabled: false,
        style: :success,
        messages: localized_messages('Service restored')
      )

      patch enable_admin_site_banner_path(banner)

      assert_redirected_to admin_site_banner_path(banner)
      assert banner.reload.enabled?
    end

    test 'system user can delete a site banner' do
      banner = SiteBanner.create!(
        enabled: false,
        style: :info,
        messages: {}
      )

      assert_difference -> { SiteBanner.count }, -1 do
        delete admin_site_banner_path(banner)
      end

      assert_redirected_to admin_site_banners_path
    end

    private

    def localized_messages(message)
      I18n.available_locales.index_with { |_locale| message }
    end
  end
end
