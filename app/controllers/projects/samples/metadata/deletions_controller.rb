# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata Deletions Controller
      class DeletionsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream

        def new
          authorize! @sample.project, to: :update_sample?
          render turbo_stream: turbo_stream.update('sample_modal',
                                                   partial: 'modal',
                                                   locals: {
                                                     open: true
                                                   }), status: :ok
        end

        def destroy
          metadata_fields_update = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                          deletion_params).execute

          status = get_destroy_status(metadata_fields_update[:deleted])
          messages = get_destroy_messages(metadata_fields_update[:deleted])

          render status:, locals: { messages: }
        end

        private

        def deletion_params
          params.require(:sample).permit(metadata: {})
        end

        def get_destroy_status(deleted_keys)
          if @sample.errors.any? && deleted_keys.count.positive?
            :multi_status
          elsif @sample.errors.any?
            :unprocessable_entity
          else
            :ok
          end
        end

        def get_destroy_messages(deleted_keys)
          messages = []

          if deleted_keys.count == 1
            messages << { type: 'success',
                          message: t('projects.samples.metadata.deletions.destroy.single_success',
                                     deleted_key: deleted_keys[0]) }
          elsif deleted_keys.count.positive?
            messages << { type: 'success',
                          message: t('projects.samples.metadata.deletions.destroy.multi_success',
                                     deleted_keys: deleted_keys.join(', ')) }
          end
          messages << { type: 'error', message: @sample.errors.full_messages.first } if @sample.errors.any?
          messages
        end
      end
    end
  end
end
