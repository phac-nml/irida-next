# frozen_string_literal: true

# root controller for samples
class SamplesController < ApplicationController
  before_action :sample

  def show
    authorize! @sample.project, to: :read_sample?

    redirect_to(namespace_project_sample_path(@sample.project.namespace.parent, @sample.project, @sample))
  end

  def edit
    authorize! @sample.project, to: :update_sample?

    redirect_to(edit_namespace_project_sample_path(@sample.project.namespace.parent, @sample.project, @sample))
  end

  private

  def sample
    @sample = Sample.includes(:project).find_by(id: params[:id] || params[:sample_id]) || not_found
  end
end
