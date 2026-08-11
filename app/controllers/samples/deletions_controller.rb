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

    def destroy # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      if Flipper.enabled?(:sample_deletion_reason, current_user)
        @sample_deletion_form = SampleDeletionForm.new(reason: destroy_params[:reason])
        return render status: :unprocessable_content unless @sample_deletion_form.valid?
      end

      samples_to_delete_count = destroy_params[:sample_ids].count

      deleted_samples_count = destroy_service

      if @namespace.errors.empty?
        # No selected samples deleted
        if deleted_samples_count.zero?
          flash[:error] = t('.no_deleted_samples')
        # Partial sample deletion
        elsif deleted_samples_count.positive? && deleted_samples_count != samples_to_delete_count
          flash[:success] = t('.partial_success',
                              deleted: "#{deleted_samples_count}/#{samples_to_delete_count}")
          flash[:error] = t('.partial_error',
                            not_deleted: "#{samples_to_delete_count - deleted_samples_count}/#{samples_to_delete_count}") # rubocop:disable Layout/LineLength
        # All samples deleted successfully
        else
          flash[:success] = t('.success', count: deleted_samples_count)
        end
      else
        flash[:error] = @namespace.errors.full_messages.join(', ')
      end

      redirect_to redirect_path, status: :see_other
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
      deletion_params = params.expect(deletion: [{ sample_ids: [] }])
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
