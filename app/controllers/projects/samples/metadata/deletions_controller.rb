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
          puts 'DESTROY!'
          puts params

          metadata_fields_update = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                                          deletion_params).execute
          if @sample.errors.any?
            puts 'hi'
          else
            render status: :ok, locals: { type: 'success',
                                          message: t('.success',
                                                     deleted_keys: metadata_fields_update[:deleted].join(', ')) }
          end
        end

        private

        def deletion_params
          params.require(:sample).permit(metadata: {})
        end
      end
    end
  end
end
