# frozen_string_literal: true

module Samples
  # controller for sample cloning
  class ClonesController < ApplicationController
    respond_to :turbo_stream
    before_action :namespace, :projects, :ensure_enabled

    def new
      authorize! (@namespace.group_namespace? ? @namespace : @namespace.project), to: :clone_sample?
      @broadcast_target = "samples_clone_#{SecureRandom.uuid}"
    end

    def create
      @broadcast_target = params[:broadcast_target]
      new_project_id = clone_params[:new_project_id]
      sample_ids = clone_params[:sample_ids]

      Samples::CloneJob.set(wait_until: 1.second.from_now).perform_later(
        @namespace, current_user, new_project_id, sample_ids, @broadcast_target
      )

      render status: :ok
    end

    private

    def clone_params
      params.expect(clone: [:new_project_id, { sample_ids: [] }])
    end

    def namespace
      @namespace = Namespace.find_by(id: params[:namespace_id])
    end

    def projects
      @projects = authorized_scope(Project, type: :relation, as: :manageable)

      return unless @namespace.project_namespace?

      @projects = @projects.where.not(namespace_id: @namespace.id)
    end

    def ensure_enabled
      not_found unless Flipper.enabled?(:group_samples_clone)
    end
  end
end
