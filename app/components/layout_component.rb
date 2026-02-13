# frozen_string_literal: true

# Overall layout component
class LayoutComponent < Component
  attr_reader :layout, :site_banners, :user

  renders_one :sidebar, Layout::SidebarComponent
  renders_one :body
  renders_one :breadcrumb, Layout::BreadcrumbComponent
  renders_one :language_selection, Layout::LanguageSelectionComponent

  def initialize(user:, fixed: true, **system_arguments)
    @user = user
    @layout = fixed ? 'container mx-auto' : ''
    @site_banners = fetch_site_banners
    @system_arguments = system_arguments
  end

  private

  def fetch_site_banners
    Rails.cache.fetch(site_banner_cache_key, expires_in: 1.hour) do
      Irida::SiteBanner.messages
    end
  end

  def site_banner_cache_key
    path = Irida::SiteBanner::DEFAULT_PATH
    mtime = File.exist?(path) ? File.mtime(path).to_i : 0
    ['site_banners', I18n.locale, mtime]
  end
end
