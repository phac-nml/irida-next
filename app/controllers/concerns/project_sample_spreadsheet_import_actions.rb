# frozen_string_literal: true

# Common Sample Spreadsheet import actions
module ProejctSampleSpreadsheetImportActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
  end

  def new
    @broadcast_target = "samples_import_#{SecureRandom.uuid}"
  end

  def create # rubocop:disable Metrics/AbcSize
    @broadcast_target = params[:broadcast_target]

    blob = ActiveStorage::Blob.create_and_upload!(
      io: spreadsheet_import_params[:file],
      filename: spreadsheet_import_params[:file].original_filename,
      content_type: spreadsheet_import_params[:file].content_type
    )

    ::Samples::BatchSampleImportJob.set(
      wait_until: 1.second.from_now
    ).perform_later(
      @namespace, current_user,
      @broadcast_target, blob.id, spreadsheet_import_params.except(:file)
    )

    render status: :ok
  end

  private

  def spreadsheet_import_params
    params.expect(spreadsheet_import: %i[file sample_name_column sample_description_column])
  end
end
