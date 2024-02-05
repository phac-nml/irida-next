# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata Fields Controller
      class FieldsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream

        def create
          authorize! @project, to: :update_sample?
          create_metadata_fields =
            ::Samples::Metadata::Fields::CreateService.new(@project, @sample, current_user,
                                                           add_field_params['add_fields']).execute

          if @sample.errors.any?
            render status: :unprocessable_entity, locals: { type: 'error', message: @sample.errors.full_messages.first }
          else
            render_params = get_add_status_and_messages(create_metadata_fields[:added_keys],
                                                        create_metadata_fields[:existing_keys])
            render status: render_params[:status], locals: { messages: render_params[:messages] }
          end
        end

        # Param is received as:
        # params: {sample: {edit_field: {key: {old_key: new_key}, value: {old_value: new_value}}}
        # Fields that have not been changed will have equal old and new
        def update # rubocop:disable Metrics/AbcSize
          authorize! @project, to: :update_sample?
          updated_metadata_field = ::Samples::Metadata::Fields::UpdateService.new(@project, @sample, current_user,
                                                                                  edit_field_params).execute
          if @sample.errors.any?
            render status: :unprocessable_entity,
                   locals: { key: edit_field_params['update_field']['key'].keys[0],
                             value: edit_field_params['update_field']['value'].keys[0] }
          else
            render_params = get_update_status_and_message(updated_metadata_field)
            render status: render_params[:status], locals: { type: render_params[:message][:type],
                                                             message: render_params[:message][:message] }
          end
        end

        private

        def add_field_params
          params.require(:sample).permit(add_fields: {})
        end

        def edit_field_params
          params.require(:sample).permit(update_field: { key: {}, value: {} })
        end

        def get_add_status_and_messages(added_keys, existing_keys)
          params = { status: '', messages: [] }
          success_msg = { type: 'success', message: t('.success', keys: added_keys.join(', ')) }
          error_msg = { type: 'error', message: t('.keys_exist', keys: existing_keys.join(', ')) }

          if added_keys.count.positive? && existing_keys.count.positive?
            params[:status] = :multi_status
            params[:messages] = [success_msg, error_msg]
          elsif existing_keys.count.positive?
            params[:status] = :unprocessable_entity
            params[:messages] = [error_msg]
          else
            params[:status] = :ok
            params[:messages] = [success_msg]
          end
          params
        end

        def get_update_status_and_message(updated_metadata_field)
          render_params = {}
          modified_metadata = updated_metadata_field[:added] + updated_metadata_field[:updated] +
                              updated_metadata_field[:deleted]
          if modified_metadata.count.positive?
            render_params[:status] = :ok
            render_params[:message] = { type: 'success', message: t('.success') }
          else
            render_params[:status] = :unprocessable_entity
            render_params[:message] = { type: 'error', message: @sample.errors.full_messages.first }
          end
          render_params
        end
      end
    end
  end
end
