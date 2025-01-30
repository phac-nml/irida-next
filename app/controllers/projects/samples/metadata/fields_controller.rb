# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata Fields Controller
      class FieldsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream

        # Param received as:
        # params: {sample: {create_fields: {key1: value1, key2: value2, ...}}}
        def create
          authorize! @project, to: :update_sample?
          create_metadata_fields =
            ::Samples::Metadata::Fields::CreateService.new(@project, @sample, current_user,
                                                           create_field_params['create_fields']).execute

          if @sample.errors.any?
            render status: :unprocessable_entity, locals: { type: 'error', message: error_message(@sample) }
          else
            status = get_create_status(create_metadata_fields[:added_keys], create_metadata_fields[:existing_keys])
            messages = get_create_messages(create_metadata_fields[:added_keys], create_metadata_fields[:existing_keys])
            render status:, locals: { messages: }
          end
        end

        # Param is received as:
        # params: {sample: {update_field: {key: {old_key: new_key}, value: {old_value: new_value}}}
        # Fields that have not been changed will have equal old and new
        def update # rubocop:disable Metrics/AbcSize
          authorize! @project, to: :update_sample?
          updated_metadata_field = ::Samples::Metadata::Fields::UpdateService.new(@project, @sample, current_user,
                                                                                  update_field_params).execute
          if @sample.errors.any?
            render status: :unprocessable_entity,
                   locals: { key: update_field_params['update_field']['key'].keys[0],
                             value: update_field_params['update_field']['value'].keys[0] }
          else
            update_render_params = get_update_status_and_message(updated_metadata_field)
            render status: update_render_params[:status], locals: { type: update_render_params[:message][:type],
                                                                    message: update_render_params[:message][:message] }
          end
        end

        private

        def create_field_params
          params.require(:sample).permit(create_fields: {})
        end

        def update_field_params
          params.require(:sample).permit(update_field: { key: {}, value: {} })
        end

        def get_create_status(added_keys, existing_keys)
          if added_keys.count.positive? && existing_keys.count.positive?
            :multi_status
          elsif existing_keys.count.positive?
            :unprocessable_entity
          else
            :ok
          end
        end

        def get_create_messages(added_keys, existing_keys) # rubocop:disable Metrics/MethodLength
          messages = []
          if added_keys.count == 1
            messages << { type: 'success',
                          message: t('projects.samples.metadata.fields.create.single_success', key: added_keys[0]) }
          elsif added_keys.count.positive?
            messages << { type: 'success',
                          message: t('projects.samples.metadata.fields.create.multi_success',
                                     keys: added_keys.join(', ')) }
          end

          if existing_keys.count == 1
            messages << { type: 'error',
                          message: t('projects.samples.metadata.fields.create.single_key_exists',
                                     key: existing_keys[0]) }
          elsif existing_keys.count.positive?
            messages << { type: 'error',
                          message: t('projects.samples.metadata.fields.create.multi_keys_exists',
                                     keys: existing_keys.join(', ')) }
          end
          messages
        end

        def get_update_status_and_message(updated_metadata_field)
          update_render_params = {}
          modified_metadata = updated_metadata_field[:added] + updated_metadata_field[:updated] +
                              updated_metadata_field[:deleted]
          if modified_metadata.count.positive?
            update_render_params[:status] = :ok
            update_render_params[:message] =
              { type: 'success', message: t('projects.samples.metadata.fields.update.success') }
          else
            update_render_params[:status] = :unprocessable_entity
            update_render_params[:message] = { type: 'error', message: error_message(@sample) }
          end
          update_render_params
        end
      end
    end
  end
end
