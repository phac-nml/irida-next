# frozen_string_literal: true

module Groups
  module Samples
    # Controller actions for Group Samples Spreadsheet Import Controller
    class SpreadsheetImportsController < Groups::ApplicationController
      include SampleSpreadsheetImportActions

      before_action :ensure_enabled

      respond_to :turbo_stream

      private

      def namespace
        @namespace = group
      end

      def group
        @group = Group.find_by_full_path(params[:group_id]) # rubocop:disable Rails/DynamicFindBy
      end

      def ensure_enabled
        not_found unless Flipper.enabled?(:batch_sample_spreadsheet_import)
      end

      def spreadsheet_import_params
        params.expect(spreadsheet_import: %i[file sample_name_column project_puid_column sample_description_column])
      end
    end
  end
end
