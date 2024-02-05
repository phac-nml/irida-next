# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata Fields Controller
      class DeletionsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream

        def new
          authorize! @sample, to: :destroy_attachment?
          render turbo_stream: turbo_stream.update('sample_modal',
                                                   partial: 'modal',
                                                   locals: {
                                                     open: true
                                                   }), status: :ok
        end

        def destroy
          metadata_fields_update = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                          deletion_params).execute

          destroy_render_params = get_destroy_status_and_messages(metadata_fields_update[:deleted])

          render status: destroy_render_params[:status], locals: { messages: destroy_render_params[:messages] }
        end

        private

        def deletion_params
          params.require(:sample).permit(metadata: {})
        end

        def get_destroy_status_and_messages(deleted_keys)
          destroy_render_params = { status: '', messages: [] }
          success_msg = { type: 'success', message: t('.success',
                                                      deleted_keys: deleted_keys.join(', ')) }
          error_msg = { type: 'error', message: @sample.errors.full_messages.first }

          if @sample.errors.any? && deleted_keys.count.positive?
            destroy_render_params[:status] = :multi_status
            destroy_render_params[:messages] = [success_msg, error_msg]
          elsif @sample.errors.any?
            destroy_render_params[:status] = :unprocessable_entity
            destroy_render_params[:messages] = [error_msg]
          else
            destroy_render_params[:status] = :ok
            destroy_render_params[:messages] = [success_msg]
          end
          destroy_render_params
        end
      end
    end
  end
end
