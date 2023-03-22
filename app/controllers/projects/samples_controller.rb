# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class SamplesController < ApplicationController
    before_action :sample, only: %i[show edit update destroy]
    before_action :project, only: %i[create]

    def index
      @samples = Sample.all
    end

    def show; end

    def new
      @sample = Sample.new
    end

    def edit; end

    def create
      @sample = Sample.new(sample_params.merge(project: @project))

      respond_to do |format|
        if @sample.save
          format.html { redirect_to namespace_project_sample_path(id: @sample.id), notice: t('.success') }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @sample.update(sample_params)
          format.html { redirect_to namespace_project_sample_path(id: @sample.id), notice: t('.success') }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      if @sample.destroy
        flash[:success] = t('.success', sample_name: @sample.name)
        redirect_to namespace_project_samples_path
      else
        flash[:error] = t('.error', sample_name: @sample.name)
        redirect_to namespace_project_sample_path(@sample)
      end
    end

    private

    def sample
      @sample = Sample.find(params[:id])
    end

    def sample_params
      params.require(:sample).permit(:name, :description)
    end

    def project
      @project ||= Namespaces::ProjectNamespace.find_by(path: params[:project_id]).project if params[:project_id]
    end
  end
end
