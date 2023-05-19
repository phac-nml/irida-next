# frozen_string_literal: true

module Projects
  # Controller actions for Project Samples Transer
  class SamplesTransferController < ApplicationController
    before_action :project
    before_action :projects, only: [:new]

    def new
      @sample_transfer = SampleTransfer.new
    end

    def create
      @sample_transfer = SampleTransfer.new(sample_transfer_params)
      if Samples::TransferService.new(current_user).execute(@sample_transfer)
        flash[:success] = t('.success')
      else
        flash[:error] = t('.error')
      end
      redirect_to namespace_project_samples_path
    end

    private

    def sample_transfer_params
      params.require(:sample_transfer).permit(:project_id, sample_ids: [])
    end

    def project
      path = [params[:namespace_id], params[:project_id]].join('/')
      @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
    end

    def projects
      @projects = Project.where(namespace: { parent: current_user.groups.self_and_descendant_ids })
                         .or(Project.where(namespace: { parent: current_user.namespace })).include_route
    end
  end
end
