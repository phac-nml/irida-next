# frozen_string_literal: true

module Projects
  # Controller actions for Project Samples Transfer
  class SamplesTransferController < ApplicationController
    before_action :project
    before_action :projects

    def new; end

    def create
      if Samples::TransferService.new(@project, current_user).execute(sample_transfer_params[:new_project_id],
                                                                      sample_transfer_params[:sample_ids])
        flash[:success] = t('.success')
        redirect_to namespace_project_samples_path
      else
        render :new, status: :unprocessable_entity
      end
    end

    private

    def sample_transfer_params
      params.permit(:new_project_id, sample_ids: [])
    end

    def project
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
    end

    def projects
      @projects = authorized_scope(Project, type: :relation, as: :transferable)
    end
  end
end
