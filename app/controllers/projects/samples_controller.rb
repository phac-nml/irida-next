# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class SamplesController < ApplicationController
    before_action :set_sample, only: %i[show edit update destroy]
    before_action :project, only: %i[create update]

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
          format.html { redirect_to namespace_project_sample_url(id: @sample.id), notice: t(:'.success') }
        else
          format.html { render :new, status: :unprocessable_entity }
        end
      end
    end

    def update
      respond_to do |format|
        if @sample.update(sample_params)
          format.html { redirect_to namespace_project_sample_url(id: @sample.id), notice: t(:'.success') }
        else
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    def destroy
      @sample.destroy

      respond_to do |format|
        format.html { redirect_to namespace_project_samples_url, notice: t(:'.success') }
      end
    end

    private

    def set_sample
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
