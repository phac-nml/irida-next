# frozen_string_literal: true

# Common sample actions
`module SampleActions
  extend ActiveSupport::Concern

  def list
    @page = params[:page].to_i
    @samples = Sample.where(id: params[:sample_ids])

    respond_to do |format|
      format.turbo_stream do
        render status: :ok
      end
    end
  end
end
