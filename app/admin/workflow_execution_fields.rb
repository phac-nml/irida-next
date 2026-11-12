# frozen_string_literal: true

ActiveAdmin.register_page 'Workflow Execution Fields' do # rubocop:disable Metrics/BlockLength
  menu priority: 25, label: proc { I18n.t('active_admin.workflow_execution_fields.title') }

  content title: proc { I18n.t('active_admin.workflow_execution_fields.title') } do # rubocop:disable Metrics/BlockLength
    setting = ApplicationSetting.current
    submitted = flash[:workflow_execution_fields_input]
    json_value = submitted || JSON.pretty_generate(setting&.workflow_execution_fields || {})
    errors = Array(flash[:workflow_execution_fields_errors])

    para I18n.t('active_admin.workflow_execution_fields.description'),
         class: 'mb-4 text-sm text-gray-600 dark:text-gray-400'

    if errors.any?
      div class: 'mb-4 rounded-md border border-red-300 bg-red-50 p-4 dark:border-red-700 dark:bg-red-900' do
        para I18n.t('active_admin.workflow_execution_fields.errors_title'),
             class: 'font-semibold text-red-800 dark:text-red-200'
        ul class: 'mt-2 list-disc pl-5 text-sm text-red-700 dark:text-red-300' do
          errors.each { |message| li message }
        end
      end
    end

    form action: admin_workflow_execution_fields_update_path, method: 'post' do
      input type: 'hidden', name: '_method', value: 'patch'
      input type: 'hidden', name: 'authenticity_token', value: form_authenticity_token

      label I18n.t('active_admin.workflow_execution_fields.field_label'),
            for: 'workflow_execution_fields',
            class: 'block text-sm font-medium text-gray-900 dark:text-gray-100'

      para I18n.t('active_admin.workflow_execution_fields.field_hint'),
           class: 'mb-2 text-sm text-gray-500 dark:text-gray-400'

      textarea json_value,
               id: 'workflow_execution_fields',
               name: 'workflow_execution_fields',
               rows: 20,
               spellcheck: 'false',
               class: 'block w-full rounded-lg border border-gray-300 bg-gray-50 p-2.5 font-mono text-sm ' \
                      'text-gray-900 dark:border-gray-600 dark:bg-gray-700 dark:text-white'

      div class: 'mt-4' do
        input type: 'submit',
              value: I18n.t('active_admin.workflow_execution_fields.save'),
              class: 'action-item-button'
      end
    end
  end

  page_action :update, method: :patch do
    setting = ApplicationSetting.current || ApplicationSetting.create_from_defaults
    submitted = params[:workflow_execution_fields].to_s

    begin
      setting.workflow_execution_fields = JSON.parse(submitted)
    rescue JSON::ParserError => e
      flash[:workflow_execution_fields_input] = submitted
      flash[:workflow_execution_fields_errors] =
        [I18n.t('active_admin.workflow_execution_fields.flash.parse_error', message: e.message)]
      redirect_to admin_workflow_execution_fields_path,
                  alert: I18n.t('active_admin.workflow_execution_fields.flash.error')
      next
    end

    if setting.save
      redirect_to admin_workflow_execution_fields_path,
                  notice: I18n.t('active_admin.workflow_execution_fields.flash.success')
    else
      flash[:workflow_execution_fields_input] = submitted
      flash[:workflow_execution_fields_errors] = setting.errors.full_messages
      redirect_to admin_workflow_execution_fields_path,
                  alert: I18n.t('active_admin.workflow_execution_fields.flash.error')
    end
  end
end
