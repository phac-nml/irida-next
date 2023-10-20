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

          render turbo_stream: [], status: :ok
        end

        private

        def concatenation_params
          params.permit(basename:, delete_originals:, attachment_ids: [])
        end
      end
    end
  end
end
