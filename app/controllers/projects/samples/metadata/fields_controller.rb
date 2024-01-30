# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata Fields Controller
      class FieldsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream
        def create
          authorize! @project, to: :update_sample?
          metadata_fields = ::Samples::Metadata::Fields::AddService.new(@project, @sample, current_user,
                                                                        add_field_params['add_fields']).execute

          if @sample.errors.any?
            render status: :unprocessable_entity,
                   locals: { type: 'error', message: @sample.errors.full_messages.first }
          else
            render_params = get_add_status_and_messages(metadata_fields[:updated_metadata_fields][:added],
                                                        metadata_fields[:existing_keys])
            render status: render_params[:status],
                   locals: { messages: render_params[:messages] }
          end
        end

        private

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
      end
    end
  end
end
