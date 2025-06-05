# frozen_string_literal: true

module Samples
  # global controller for sample transfers
  class TransfersController < ApplicationController
    respond_to :turbo_stream
    before_action :projects
    before_action :namespace

    def new
      if @namespace.group_namespace?
        authorize! @namespace, to: :transfer_sample?
      else
        authorize! @namespace.project, to: :transfer_sample?
      end

      @broadcast_target = "samples_transfer_#{SecureRandom.uuid}"
    end

    def create
      @broadcast_target = params[:broadcast_target]
      new_project_id = transfer_params[:new_project_id]
      sample_ids = transfer_params[:sample_ids]
      Samples::TransferJob.set(wait_until: 1.second.from_now).perform_later(@namespace, current_user,
                                                                            new_project_id,
                                                                            sample_ids, @broadcast_target)

      render status: :ok
    end

    private

    def transfer_params
      params.expect(transfer: [:new_project_id, { sample_ids: [] }])
    end

    def projects
      scope_options = namespace.group_namespace? ? { group: namespace } : { project: namespace }

      @projects = authorized_scope(Project, type: :relation, as: :project_samples_transferable,
                                            scope_options: scope_options)

      @projects = @projects.where.not(namespace_id: namespace.id) if @namespace.project_namespace?
    end

    def namespace
      @namespace = Namespace.find(params[:namespace_id])
    end
  end
end
