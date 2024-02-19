# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Clone Controller
    class ClonesController < Projects::ApplicationController
      respond_to :turbo_stream

      def create
        new_project_id = clone_params[:new_project_id]
        sample_ids = clone_params[:sample_ids]

        @cloned_sample_ids = ::Samples::CloneService.new(@project, current_user).execute(new_project_id, sample_ids)

        if @project.errors.empty?
          render status: :ok, locals: { type: :success, message: t('.success') }
        elsif @project.errors.include?(:sample)
          render_sample_errors
        else
          error = @project.errors.full_messages_for(:base).first
          render status: :unprocessable_entity, locals: { type: :danger, message: error }
        end
      end

      private

      def clone_params
        params.require(:clone).permit(:new_project_id, sample_ids: [])
      end

      def render_sample_errors
        errors = @project.errors.messages_for(:sample)
        if @cloned_sample_ids.count.positive?
          render status: :partial_content, locals: { type: :alert, message: t('.error'), errors: }
        else
          render status: :unprocessable_entity, locals: { type: :alert, message: t('.error'), errors: }
        end
      end
    end
  end
end
