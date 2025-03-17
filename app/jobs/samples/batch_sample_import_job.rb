# frozen_string_literal: true

module Samples
  # Job used to import metadata for samples
  class BatchSampleImportJob < ApplicationJob
    queue_as :default

    def perform(namespace, current_user, broadcast_target, blob_id, params) # rubocop:disable Metrics/MethodLength
      response = ::Samples::BatchFileImportService.new(namespace, current_user, blob_id, params).execute

      if namespace.errors.empty?
        handle_success(broadcast_target, response)

      elsif namespace.errors.include?(:sample)
        errors = namespace.errors.messages_for(:sample)

        Turbo::StreamsChannel.broadcast_replace_to(
          broadcast_target,
          target: 'import_spreadsheet_dialog_content',
          partial: 'shared/samples/spreadsheet_imports/errors',
          locals: {
            type: :alert,
            message: I18n.t('shared.samples.spreadsheet_imports.errors.description'),
            errors: errors
          }
        )
      else
        errors = namespace.errors.full_messages_for(:base)

        Turbo::StreamsChannel.broadcast_replace_to(
          broadcast_target,
          target: 'import_spreadsheet_dialog_content',
          partial: 'shared/samples/spreadsheet_imports/errors',
          locals: {
            type: :alert,
            errors: errors
          }
        )
      end
    end

    private

    def handle_success(broadcast_target, response) # rubocop:disable Metrics/MethodLength
      results = []
      response.each do |key, value|
        if value.is_a? Sample
          results.push({ sample_name: key,
                         sample_id: value.puid,
                         completed: true,
                         message: nil })
        else
          results.push({ sample_name: key,
                         sample_id: nil,
                         completed: false,
                         message: value })
        end
      end

      Turbo::StreamsChannel.broadcast_replace_to(
        broadcast_target,
        target: 'import_spreadsheet_dialog_content',
        partial: 'shared/samples/spreadsheet_imports/success',
        locals: {
          type: :success,
          message: I18n.t('shared.samples.spreadsheet_imports.success.description'),
          results:
        }
      )
    end
  end
end
