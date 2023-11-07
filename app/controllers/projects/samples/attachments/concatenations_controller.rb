# frozen_string_literal: true

module Projects
  module Samples
    module Attachments
      # Controller actions for Project Samples Attachments Concatenation
      class ConcatenationsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream

        def new
          authorize! @project, to: :update_sample?

          render turbo_stream: [], status: :ok
        end

        def create
          authorize! @project, to: :update_sample?

          @concatenated_attachments = ::Attachments::ConcatenationService.new(current_user, @sample,
                                                                              concatenation_params).execute

          if @sample.errors.empty?
            render turbo_stream: [], status: :ok
          else
            @errors = @sample.errors.full_messages_for(:base)
            render turbo_stream: [], status: :unprocessable_entity
          end
        end

        private

        def concatenation_params
          params.permit(:basename, :delete_originals, attachment_ids: [])
        end
      end
    end
  end
end
