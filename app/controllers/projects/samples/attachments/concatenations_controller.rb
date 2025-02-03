# frozen_string_literal: true

module Projects
  module Samples
    module Attachments
      # Controller actions for Project Samples Attachments Concatenation
      class ConcatenationsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream

        def new
          authorize! @project, to: :update_sample?
          render turbo_stream: turbo_stream.update('sample_modal',
                                                   partial: 'modal',
                                                   locals: {
                                                     open: true
                                                   }), status: :ok
        end

        def create
          authorize! @project, to: :update_sample?

          @concatenated_attachments = ::Attachments::ConcatenationService.new(current_user, @sample,
                                                                              concatenation_params).execute

          if @sample.errors.empty?
            render status: :ok, locals: { type: :success, message: t('.success') }
          else
            @errors = error_message(@sample)
            render status: :unprocessable_entity, locals: { type: :danger,
                                                            message: @errors }
          end
        end

        private

        def concatenation_params
          params.require(:concatenation).permit(:basename, :delete_originals, attachment_ids: {})
        end
      end
    end
  end
end
