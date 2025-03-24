# frozen_string_literal: true

# Common metadata spreadsheet import actions
module MetadataSpreadsheetImportActions
  extend ActiveSupport::Concern

  included do
    before_action proc { namespace }
  end

  def new
    @broadcast_target = "metadata_import_#{SecureRandom.uuid}"
  end

  def create
    @broadcast_target = params[:broadcast_target]

    blob = ActiveStorage::Blob.find_signed!(file_import_params[:file])

    ::Samples::MetadataImportJob.set(
      wait_until: 1.second.from_now
    ).perform_later(
      @namespace, current_user,
      @broadcast_target, blob.id, file_import_params.except(:file)
    )

    render status: :ok
  end

  private

  def file_import_params
    params.expect(file_import: [:file, :sample_id_column, :ignore_empty_values, { metadata_columns: [] }])
  end
end
