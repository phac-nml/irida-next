# frozen_string_literal: true

module Samples
  # controller for sample deletions
  class DeletionsController < ApplicationController
    include ListActions

    before_action :namespace, only: %i[new destroy]
    before_action :confirmation_parameters, :sample, only: %i[new destroy]

    def new
      authorize! (@namespace.group_namespace? ? @namespace : @namespace.project), to: :destroy_sample?

      @sample_deletion_form = SampleDeletionForm.new if Flipper.enabled?(:sample_deletion_reason, current_user)
      @broadcast_target = "samples_destroy_#{SecureRandom.uuid}"
    end

    def destroy
      if Flipper.enabled?(:sample_deletion_reason, current_user)
        @sample_deletion_form = SampleDeletionForm.new(reason: destroy_params[:reason])
        return render status: :unprocessable_content unless @sample_deletion_form.valid?
      end

      samples_to_delete_count = destroy_params[:sample_ids].count

      deleted_samples_count = destroy_service

      if @namespace.errors.empty?
        set_deletion_flash_messages(deleted_samples_count, samples_to_delete_count)
        redirect_to redirect_path, status: :see_other
      else
        render_deletion_errors
      end
    end

    private

    def namespace
      @namespace = Namespace.find_by(id: params[:namespace_id])
    end

    def confirmation_parameters
      @confirmation_dialog = "destroy_#{params[:deletion_type]}_confirmation_dialog"
    end

    def sample
      @sample = Sample.find_by(id: params[:sample_id])
    end

    def destroy_params
      # Make reason optional by only extracting what's provided
      deletion_params = params.expect(deletion: { sample_ids: [] })
      if Flipper.enabled?(:sample_deletion_reason, current_user)
        deletion_params[:reason] = params.dig(:deletion, :reason)
      end
      deletion_params
    end

    def destroy_service
      if @namespace.group_namespace?
        Groups::Samples::DestroyService.new(@namespace, current_user, destroy_params).execute
      else
        Projects::Samples::DestroyService.new(@namespace, current_user, destroy_params).execute
      end
    end

    def set_deletion_flash_messages(deleted_count, total_count)
      if deleted_count.zero?
        flash[:error] = t('samples.deletions.destroy.no_deleted_samples')
      elsif deleted_count.positive? && deleted_count != total_count
        flash[:success] =
          t('samples.deletions.destroy.partial_success',
            deleted: "#{deleted_count}/#{total_count}")
        flash[:error] = t('samples.deletions.destroy.partial_error',
                          not_deleted: "#{total_count - deleted_count}/#{total_count}")
      else
        flash[:success] = t('samples.deletions.destroy.success', count: deleted_count)
      end
    end

    def render_deletion_errors
      render turbo_stream: turbo_stream.update('samples_dialog',
                                               partial: @confirmation_dialog,
                                               locals: {
                                                 errors: @namespace.errors.full_messages,
                                                 open: true,
                                                 closable: false
                                               }), status: :unprocessable_content
    end

    def redirect_path
      @namespace.group_namespace? ? group_redirect_path : project_redirect_path
    end

    def group_redirect_path
      group_samples_path(@namespace)
    end

    def project_redirect_path
      namespace_project_samples_path(@namespace.parent, @namespace.project)
    end
  end
end
