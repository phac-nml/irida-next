# frozen_string_literal: true

module Projects
  # Controller actions for Project Samples Transer
  class SamplesTransferController < ApplicationController
    before_action :project
    before_action :projects, only: [:new]

    def new
      puts '-------- I AM HERE --------'
      puts params
      @sample_transfer = SampleTransfer.new
    end

    def create
      @sample_transfer = SampleTransfer.new(params[:sample_transfer])
      if @sample_transfer.valid?
        if Samples::TransferService.new.execute
          flash[:success] = t('.success')
        else
          flash[:error] = t('.error')
        end
        redirect_to namespace_project_samples_path
      else
        render :new
      end
    end

    private

    def sample_transfer_params
      params.require(:sample_transfer).permit(:project, :samples)
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
