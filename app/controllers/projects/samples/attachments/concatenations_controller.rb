# frozen_string_literal: true

module Projects
  module Samples
    module Attachments
      # Controller actions for Project Samples Attachments Concatenation
      class ConcatenationsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream

        before_action :view_authorizations, only: %i[create]

        def new
          authorize! @project, to: :update_sample?
          render turbo_stream: turbo_stream.update('sample_modal',
                                                   partial: 'modal',
                                                   locals: {
                                                     open: true,
                                                     concatenation_params: nil
                                                   }), status: :ok
        end

        def create
          authorize! @project, to: :update_sample?

          @concatenated_attachments = ::Attachments::ConcatenationService.new(current_user, @sample,
                                                                              concatenation_params).execute

          if @sample.errors.empty?
            render status: :ok, locals: { type: :success, message: t('.success') }
          else
            error_msg = if @sample.errors[:basename].any?
                          t(:'general.form.error_notification')
                        else
                          @errors
                        end

            render status: :unprocessable_entity, locals: { type: :danger,
                                                            message: error_msg,
                                                            concatenation_params: }

          end
        end

        private

        def view_authorizations
          @allowed_to = { update_sample: allowed_to?(:update_sample?, @project),
                          destroy_attachment: allowed_to?(:destroy_attachment?, @sample) }
        end

        def concatenation_params
          params.expect(concatenation: [:basename, :delete_originals, { attachment_ids: {} }])
        end
      end
    end
  end
end
