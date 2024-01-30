# frozen_string_literal: true

module Projects
  module Samples
    module Metadata
      # Controller actions for Project Samples Metadata Fields Controller
      class FieldsController < Projects::Samples::ApplicationController
        respond_to :turbo_stream

        # Param is received as:
        # params: {sample: {edit_field: {key: {old_key: new_key}, value: {old_value: new_value}}}
        # Fields that have not been changed will have equal old and new
        def update # rubocop:disable Metrics/AbcSize
          authorize! @project, to: :update_sample?
          updated_metadata_field = ::Samples::Metadata::Fields::EditService.new(@project, @sample, current_user,
                                                                                edit_field_params).execute
          if @sample.errors.any?
            render status: :unprocessable_entity,
                   locals: { key: edit_field_params['edit_field']['key'].keys[0],
                             value: edit_field_params['edit_field']['value'].keys[0] }
          else
            render_params = get_render_status_and_message(updated_metadata_field)
            render status: render_params[:status], locals: { type: render_params[:message][:type],
                                                             message: render_params[:message][:message] }
          end
        end

        private

        def edit_field_params
          params.require(:sample).permit(edit_field: {})
        end

        def get_render_status_and_message(updated_metadata_field)
          render_params = {}
          modified_metadata = updated_metadata_field[:added] + updated_metadata_field[:updated] +
                              updated_metadata_field[:deleted]
          if modified_metadata.count.positive?
            render_params[:status] = :ok
            render_params[:message] = { type: 'success', message: t('.success') }
          else
            render_params[:status] = :unprocessable_entity
            render_params[:message] = { type: 'error', message: @sample.errors.full_messages.first }
          end
          render_params
        end
      end
    end
  end
end
