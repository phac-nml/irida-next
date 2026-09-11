# frozen_string_literal: true

ActiveAdmin.register_page 'Feature Flags' do # rubocop:disable Metrics/BlockLength
  menu priority: 20, label: proc { I18n.t('active_admin.feature_flags.title') }

  content title: proc { I18n.t('active_admin.feature_flags.title') } do # rubocop:disable Metrics/BlockLength
    para I18n.t('active_admin.feature_flags.description'),
         class: 'mb-4 text-sm text-gray-600 dark:text-gray-400'

    entries = Irida::SystemFeatureFlagsCatalog.entries

    if entries.empty?
      div class: 'py-12 text-center text-sm text-gray-500 dark:text-gray-400' do
        text_node I18n.t('active_admin.feature_flags.empty')
      end
    else
      table_for entries, class: 'index_table' do # rubocop:disable Metrics/BlockLength
        column I18n.t('active_admin.feature_flags.columns.feature') do |entry|
          div class: 'max-w-md' do
            div entry[:name], class: 'font-semibold text-gray-900 dark:text-gray-100'
            div entry[:description], class: 'text-sm text-gray-500 dark:text-gray-400'
          end
        end

        column I18n.t('active_admin.feature_flags.columns.global_state') do |entry|
          status_tag I18n.t("active_admin.feature_flags.state.#{entry[:global_state]}"),
                     class: global_state_class(entry[:global_state])
        end

        column I18n.t('active_admin.feature_flags.columns.opt_in') do |entry|
          status_tag I18n.t("active_admin.feature_flags.opt_in.#{entry[:opt_in_state]}"),
                     class: opt_in_state_class(entry[:opt_in_state])
        end

        column I18n.t('active_admin.feature_flags.columns.gates') do |entry|
          div do
            div gate_summary_text(entry[:gate_summary]),
                class: 'text-sm text-gray-600 dark:text-gray-300'
            text_node link_to I18n.t('active_admin.feature_flags.manage_gates'),
                              flipper_feature_url(entry[:key]),
                              class: 'text-sm text-indigo-600 dark:text-indigo-400',
                              target: '_blank',
                              rel: 'noopener'
          end
        end

        column I18n.t('active_admin.feature_flags.columns.actions') do |entry| # rubocop:disable Metrics/BlockLength
          div class: 'flex flex-col items-start gap-2' do
            global = global_toggle_for(entry)
            text_node link_to global[:label], global[:path],
                              class: 'action-item-button whitespace-nowrap',
                              method: :patch,
                              data: { confirm: global[:confirm] }

            opt_in = opt_in_toggle_for(entry)
            if opt_in[:disabled]
              text_node button_tag(opt_in[:label],
                                   type: 'button',
                                   disabled: true,
                                   class: 'action-item-button whitespace-nowrap',
                                   title: opt_in[:disabled_reason])
            else
              text_node link_to opt_in[:label], opt_in[:path],
                                class: 'action-item-button whitespace-nowrap',
                                method: :patch,
                                data: { confirm: opt_in[:confirm] }
            end
          end
        end # rubocop:enable Metrics/BlockLength
      end
    end
  end

  page_action :update_global_state, method: :patch do
    target_state = params[:target_state].to_s
    result = SystemFeatureFlags::UpdateGlobalState.new(
      feature_key: params[:feature_key],
      target_state: target_state,
      user: current_user
    ).execute

    redirect_to admin_feature_flags_path,
                **feature_flag_flash(result, success_key: "global_#{target_state}")
  end

  page_action :update_opt_in_availability, method: :patch do
    available = { 'true' => true, 'false' => false }[params[:available].to_s]
    result = SystemFeatureFlags::UpdateOptInAvailability.new(
      feature_key: params[:feature_key],
      available: available,
      user: current_user
    ).execute

    redirect_to admin_feature_flags_path,
                **feature_flag_flash(result, success_key: available ? 'opt_in_enabled' : 'opt_in_disabled')
  end

  controller do # rubocop:disable Metrics/BlockLength
    helper_method :global_toggle_for, :opt_in_toggle_for, :gate_summary_text,
                  :global_state_class, :opt_in_state_class, :flipper_feature_url

    def global_toggle_for(entry)
      if entry[:global_state] == 'enabled'
        {
          label: t('active_admin.feature_flags.actions.disable_globally'),
          path: admin_feature_flags_update_global_state_path(feature_key: entry[:key], target_state: 'disabled'),
          confirm: t('active_admin.feature_flags.actions.disable_globally_confirm', name: entry[:name])
        }
      else
        {
          label: t('active_admin.feature_flags.actions.enable_globally'),
          path: admin_feature_flags_update_global_state_path(feature_key: entry[:key], target_state: 'enabled'),
          confirm: t('active_admin.feature_flags.actions.enable_globally_confirm', name: entry[:name])
        }
      end
    end

    def opt_in_toggle_for(entry)
      return locked_opt_in_toggle if entry[:global_state] == 'enabled'

      available = entry[:opt_in_state] == 'off'
      action = available ? 'enable_opt_in' : 'disable_opt_in'
      {
        label: t("active_admin.feature_flags.actions.#{action}"),
        path: admin_feature_flags_update_opt_in_availability_path(feature_key: entry[:key], available: available),
        confirm: t("active_admin.feature_flags.actions.#{action}_confirm", name: entry[:name])
      }
    end

    def locked_opt_in_toggle
      {
        disabled: true,
        label: t('active_admin.feature_flags.actions.enable_opt_in'),
        disabled_reason: t('active_admin.feature_flags.actions.opt_in_locked')
      }
    end

    def gate_summary_text(summary)
      fields = [
        ['actors', 'actors', :count],
        ['groups', 'groups', :count],
        ['percentage_of_actors', 'percentage_of_actors', :percent],
        ['percentage_of_time', 'percentage_of_time', :percent],
        ['expression', 'expression', :count]
      ]
      parts = fields.filter_map do |gate_key, i18n_key, arg|
        value = summary[gate_key].to_i
        t("active_admin.feature_flags.gates.#{i18n_key}", arg => value) if value.positive?
      end
      parts.presence&.join(' · ') || t('active_admin.feature_flags.gates.none')
    end

    def global_state_class(state)
      {
        'enabled' => 'bg-green-100 text-green-800 dark:bg-green-900/30 dark:text-green-300',
        'conditional' => 'bg-amber-100 text-amber-800 dark:bg-amber-900/30 dark:text-amber-300',
        'disabled' => 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
      }.fetch(state, 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300')
    end

    def opt_in_state_class(state)
      {
        'all_users' => 'bg-blue-100 text-blue-800 dark:bg-blue-900/30 dark:text-blue-300',
        'allowlist' => 'bg-violet-100 text-violet-800 dark:bg-violet-900/30 dark:text-violet-300',
        'off' => 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300'
      }.fetch(state, 'bg-gray-100 text-gray-700 dark:bg-gray-700 dark:text-gray-300')
    end

    def flipper_feature_url(feature_key)
      "/-/system/flipper/features/#{feature_key}"
    end

    def feature_flag_flash(result, success_key:)
      if result.success?
        { notice: t("active_admin.feature_flags.flash.#{success_key}") }
      elsif result.no_op?
        { notice: t('active_admin.feature_flags.flash.no_change') }
      else
        { alert: t("active_admin.feature_flags.flash.errors.#{result.error}",
                   default: t('active_admin.feature_flags.flash.errors.generic')) }
      end
    end
  end
end
