# frozen_string_literal: true

module Samples
  # controller for sample deletions
  class DeletionsController < ApplicationController
    include ListActions
    respond_to :turbo_stream

    before_action :namespace, only: %i[new destroy_samples]
    before_action :confirmation_parameters, :sample, only: :new

    def new
      authorize! (@namespace.group_namespace? ? @namespace : @namespace.project), to: :destroy_sample?
    end

    def destroy_samples
      samples_to_delete_count = destroy_samples_params['sample_ids'].count

      deleted_samples_count = destroy_service

      # No selected samples deleted
      if deleted_samples_count.zero?
        flash[:error] = t('.no_deleted_samples')
      # Partial sample deletion
      elsif deleted_samples_count.positive? && deleted_samples_count != samples_to_delete_count
        set_multi_status_destroy_multiple_message(deleted_samples_count, samples_to_delete_count)
      # All samples deleted successfully
      else
        flash[:success] = t('.success', count: deleted_samples_count)
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

    def destroy_samples_params
      params.expect(destroy_samples: [{ sample_ids: [] }])
    end

    def set_multi_status_destroy_multiple_message(deleted_samples_count, samples_to_delete_count)
      flash[:success] = t('samples.deletions.destroy_samples.partial_success',
                          deleted: "#{deleted_samples_count}/#{samples_to_delete_count}")
      flash[:error] = t('samples.deletions.destroy_samples.partial_error',
                        not_deleted: "#{samples_to_delete_count - deleted_samples_count}/#{samples_to_delete_count}")
    end

    def destroy_service
      if @namespace.group_namespace?
        Groups::Samples::DestroyService.new(@namespace, current_user, destroy_samples_params).execute
      else
        Projects::Samples::DestroyService.new(@namespace, current_user, destroy_samples_params).execute
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
