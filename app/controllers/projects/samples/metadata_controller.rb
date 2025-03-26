# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Metadata
    class MetadataController < Projects::Samples::ApplicationController
      before_action :view_authorizations, only: %i[destroy]

      def new
        render turbo_stream: turbo_stream.update('sample_modal',
                                                 partial: 'new_metadata_modal',
                                                 locals: {
                                                   open: true
                                                 }), status: :ok
      end

      def edit
        authorize! @project, to: :update_sample?
        render turbo_stream: turbo_stream.update('sample_modal',
                                                 partial: 'update_metadata_modal',
                                                 locals: {
                                                   open: true,
                                                   key: params[:key],
                                                   value: params[:value]
                                                 }), status: :ok
      end

      def destroy # rubocop:disable Metrics/MethodLength
        metadata = ::Samples::Metadata::UpdateService.new(@project, @sample, current_user,
                                                          deletion_params).execute

        respond_to do |format|
          if metadata[:deleted].count.positive?
            format.turbo_stream do
              render status: :ok, locals: { type: 'success',
                                            message: t('.success',
                                                       deleted_key: metadata[:deleted][0]) }
            end
          else
            format.turbo_stream do
              render status: :unprocessable_entity,
                     locals: { type: 'error', message: t('.error') }
            end
          end
        end
      end

      private

      def view_authorizations
        @allowed_to = { update_sample: allowed_to?(:update_sample?, @project) }
      end

      def deletion_params
        params.expect(sample: [metadata: {}])
      end
    end
  end
end
