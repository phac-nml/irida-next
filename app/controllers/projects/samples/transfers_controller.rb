# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Transfer
    class TransfersController < ApplicationController
      before_action :projects

      def new
        authorize! @project, to: :transfer_sample?

        respond_to do |format|
          format.turbo_stream do
            render status: :ok
          end
        end
      end

      def create # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        new_project_id = transfer_params[:new_project_id]
        sample_ids = transfer_params[:sample_ids]
        transferred_samples_ids = ::Samples::TransferService.new(@project, current_user).execute(new_project_id,
                                                                                                 sample_ids)
        @pagy, @samples = pagy(Sample.where(project_id: @project.id))

        respond_to do |format|
          if transferred_samples_ids.length == sample_ids.length
            format.turbo_stream do
              render status: :ok, locals: { sample_ids:, type: :success, message: t('.success'), errors: [] }
            end
          elsif @project.errors.include?(:samples)
            @errors = @project.errors.messages_for(:samples)
            format.turbo_stream do
              render status: :partial_content,
                     locals: { sample_ids: transferred_samples_ids, type: :alert,
                               message: t('.error'), errors: @errors }
            end
          else
            @errors = @project.errors.full_messages_for(:base)
            format.turbo_stream do
              render status: :unprocessable_entity,
                     locals: { sample_ids: [], type: :alert,
                               message: @errors, errors: [] }
            end
          end
        end
      end

      private

      def transfer_params
        params.permit(:new_project_id, sample_ids: [])
      end

      def projects
        @projects = authorized_scope(Project, type: :relation, as: :manageable).where.not(namespace_id: project.namespace_id) # rubocop:disable Layout/LineLength
      end
    end
  end
end
