# frozen_string_literal: true

module Projects
  # Controller actions for Samples
  class SamplesController < ApplicationController
    before_action :set_sample, only: %i[show edit update destroy]

    # GET /samples or /samples.json
    def index
      @samples = Sample.all
    end

    # GET /samples/1 or /samples/1.json
    def show; end

    # GET /samples/new
    def new
      @sample = Sample.new
    end

    # GET /samples/1/edit
    def edit; end

    # POST /samples or /samples.json
    def create
      @sample = Sample.new(sample_params)

      respond_to do |format|
        if @sample.save
          format.html { redirect_to namespace_project_sample_url(id: @sample.id), notice: t(:'.success') }
          format.json { render :show, status: :created, location: @sample }
        else
          format.html { render :new, status: :unprocessable_entity }
          format.json { render json: @sample.errors, status: :unprocessable_entity }
        end
      end
    end

    # PATCH/PUT /samples/1 or /samples/1.json
    def update
      respond_to do |format|
        if @sample.update(sample_params)
          format.html { redirect_to namespace_project_sample_url(id: @sample.id), notice: t(:'.success') }
          format.json { render :show, status: :ok, location: @sample }
        else
          format.html { render :edit, status: :unprocessable_entity }
          format.json { render json: @sample.errors, status: :unprocessable_entity }
        end
      end
    end

    # DELETE /samples/1 or /samples/1.json
    def destroy
      @sample.destroy

      respond_to do |format|
        format.html { redirect_to namespace_project_samples_url, notice: t(:'.success') }
        format.json { head :no_content }
      end
    end

    private

    # Use callbacks to share common setup or constraints between actions.
    def set_sample
      @sample = Sample.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def sample_params
      params.require(:sample).permit(:name, :description, :project_id)
    end
  end
end
