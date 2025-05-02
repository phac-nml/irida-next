# frozen_string_literal: true

# Common Sample Spreadsheet import actions
module SampleSpreadsheetImportActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
  end

  def new
    @broadcast_target = "samples_import_#{SecureRandom.uuid}"
  end

  def create
    @broadcast_target = params[:broadcast_target]

    blob = ActiveStorage::Blob.find_signed!(spreadsheet_import_params[:file])

    ::Samples::BatchSampleImportJob.set(
      wait_until: 1.second.from_now
    ).perform_later(
      @namespace, current_user,
      @broadcast_target, blob.id, spreadsheet_import_params.except(:file)
    )

    render status: :ok
  end
end
