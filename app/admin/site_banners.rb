# frozen_string_literal: true

ActiveAdmin.register SiteBanner do # rubocop:disable Metrics/BlockLength
  permit_params :enabled, :style, messages: I18n.available_locales.map(&:to_sym)

  filter :enabled
  filter :style, as: :select, collection: SiteBanner.styles.keys
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :enabled
    column :style
    I18n.available_locales.each do |locale|
      column I18n.t('active_admin.site_banners.message_for', locale_code: locale) do |site_banner|
        truncate(site_banner.messages[locale.to_s].to_s, length: 80)
      end
    end
    column :created_at
    column :updated_at
    actions do |site_banner|
      action = toggle_action_for(site_banner)
      item action[:label], action[:path], method: :patch, data: { confirm: action[:confirm] }
    end
  end

  show do
    attributes_table do
      row :id
      row :enabled
      row :style
      I18n.available_locales.each do |locale|
        row I18n.t('active_admin.site_banners.message_for', locale_code: locale) do |site_banner|
          site_banner.messages[locale.to_s]
        end
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors

    f.inputs do
      f.input :enabled
      f.input :style, as: :select, collection: SiteBanner.styles.keys
    end

    f.inputs I18n.t('active_admin.site_banners.messages_fieldset') do
      I18n.available_locales.each do |locale|
        f.input :messages,
                as: :text,
                label: I18n.t('active_admin.site_banners.message_for', locale_code: locale),
                wrapper_html: { id: "site_banner_message_#{locale}_input" },
                input_html: {
                  id: "site_banner_message_#{locale}",
                  name: "site_banner[messages][#{locale}]",
                  rows: 3,
                  value: f.object.messages[locale.to_s]
                }
      end
    end

    f.actions
  end

  member_action :disable, method: :patch do
    resource.update!(enabled: false)

    redirect_to resource_path(resource), notice: I18n.t('active_admin.site_banners.disabled')
  end

  member_action :enable, method: :patch do
    if resource.update(enabled: true)
      redirect_to resource_path(resource), notice: I18n.t('active_admin.site_banners.enabled')
    else
      redirect_to resource_path(resource), alert: resource.errors.full_messages.to_sentence
    end
  end

  action_item :disable, only: :show, if: proc { resource.enabled? } do
    action = toggle_action_for(resource)

    link_to action[:label],
            action[:path],
            class: 'action-item-button',
            method: :patch,
            data: { confirm: action[:confirm] }
  end

  action_item :enable, only: :show, if: proc { !resource.enabled? } do
    action = toggle_action_for(resource)

    link_to action[:label],
            action[:path],
            class: 'action-item-button',
            method: :patch,
            data: { confirm: action[:confirm] }
  end

  controller do
    helper_method :toggle_action_for

    def toggle_action_for(site_banner)
      if site_banner.enabled?
        {
          label: I18n.t('active_admin.site_banners.disable'),
          path: disable_admin_site_banner_path(site_banner),
          confirm: I18n.t('active_admin.site_banners.disable_confirm')
        }
      else
        {
          label: I18n.t('active_admin.site_banners.enable'),
          path: enable_admin_site_banner_path(site_banner),
          confirm: I18n.t('active_admin.site_banners.enable_confirm')
        }
      end
    end
  end
end
