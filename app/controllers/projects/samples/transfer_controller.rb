# frozen_string_literal: true

module Projects
  module Samples
    # Controller actions for Project Samples Transfer
    class TransferController < ApplicationController
      before_action :project
      before_action :projects

      def new; end

      def create
        new_project_id = params[:new_project_id]
        sample_ids = params[:sample_ids]
        if ::Samples::TransferService.new(@project, current_user).execute(new_project_id, sample_ids)
          flash[:success] = t('.success')
          redirect_to namespace_project_samples_path
        else
          render :new, status: :unprocessable_entity
        end
      end

      private

      def transfer_params
        params.permit(:new_project_id, sample_ids: [])
      end

      def project
        path = [params[:namespace_id], params[:project_id]].join('/')
        @project ||= Namespaces::ProjectNamespace.find_by_full_path(path).project # rubocop:disable Rails/DynamicFindBy
      end

      def projects
        @projects = authorized_scope(Project, type: :relation, as: :manageable).where.not(namespace_id: project.namespace_id) # rubocop:disable Layout/LineLength
      end
    end
  end
end
