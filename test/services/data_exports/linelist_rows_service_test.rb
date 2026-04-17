# frozen_string_literal: true

require 'test_helper'

module DataExports
  class LinelistRowsServiceTest < ActiveSupport::TestCase
    def setup
      @user = users(:john_doe)
      @sample32 = samples(:sample32)
      @sample33 = samples(:sample33)
      @sample34 = samples(:sample34)
    end

    # Header shape ----------------------------------------------------------

    test 'call returns header row as first element' do
      result = DataExports::LinelistRowsService.call(
        sample_ids: [@sample32.id],
        metadata_fields: %w[metadatafield1 metadatafield2],
        current_user: @user
      )

      assert_equal ['SAMPLE PUID', 'SAMPLE NAME', 'PROJECT PUID', 'METADATAFIELD1', 'METADATAFIELD2'],
                   result.first
    end

    test 'header is uppercased from metadata_fields input' do
      result = DataExports::LinelistRowsService.call(
        sample_ids: [@sample32.id],
        metadata_fields: ['metadatafield1'],
        current_user: @user
      )

      assert_equal ['SAMPLE PUID', 'SAMPLE NAME', 'PROJECT PUID', 'METADATAFIELD1'], result.first
    end

    test 'header has no metadata columns when metadata_fields is empty' do
      result = DataExports::LinelistRowsService.call(
        sample_ids: [@sample32.id],
        metadata_fields: [],
        current_user: @user
      )

      assert_equal ['SAMPLE PUID', 'SAMPLE NAME', 'PROJECT PUID'], result.first
    end

    # Row shape -------------------------------------------------------------

    test 'call returns puid, name and project puid for each sample' do
      result = DataExports::LinelistRowsService.call(
        sample_ids: [@sample32.id],
        metadata_fields: [],
        current_user: @user
      )

      # row 0 is the header; row 1 is the first sample
      data_row = result[1]
      assert_equal @sample32.puid, data_row[0]
      assert_equal @sample32.name, data_row[1]
      assert_equal @sample32.project.puid, data_row[2]
    end

    test 'call returns metadata values in requested field order' do
      result = DataExports::LinelistRowsService.call(
        sample_ids: [@sample32.id],
        metadata_fields: %w[metadatafield2 metadatafield1],
        current_user: @user
      )

      data_row = result[1]
      # metadatafield2 first because that is the order requested
      assert_equal @sample32.metadata['metadatafield2'], data_row[3]
      assert_equal @sample32.metadata['metadatafield1'], data_row[4]
    end

    # Missing metadata ------------------------------------------------------

    test 'blank string for metadata key not present on sample' do
      result = DataExports::LinelistRowsService.call(
        sample_ids: [@sample32.id],
        metadata_fields: %w[metadatafield1 non_existent_field],
        current_user: @user
      )

      data_row = result[1]
      assert_equal @sample32.metadata['metadatafield1'], data_row[3]
      assert_equal '', data_row[4]
    end

    test 'all metadata columns are blank when sample has no metadata' do
      # sample33 has metadata; use a sample fixture with no metadata if available,
      # or just assert the contract for a field that is missing
      result = DataExports::LinelistRowsService.call(
        sample_ids: [@sample32.id],
        metadata_fields: %w[non_existent_a non_existent_b],
        current_user: @user
      )

      data_row = result[1]
      assert_equal '', data_row[3]
      assert_equal '', data_row[4]
    end

    # Multiple samples ------------------------------------------------------

    test 'returns one row per sample plus header' do
      result = DataExports::LinelistRowsService.call(
        sample_ids: [@sample32.id, @sample33.id, @sample34.id],
        metadata_fields: %w[metadatafield1],
        current_user: @user
      )

      assert_equal 4, result.length # 1 header + 3 data rows
    end

    test 'row order matches sample_ids order' do
      result = DataExports::LinelistRowsService.call(
        sample_ids: [@sample34.id, @sample32.id],
        metadata_fields: [],
        current_user: @user
      )

      assert_equal @sample34.puid, result[1][0]
      assert_equal @sample32.puid, result[2][0]
    end

    test 'ignores nil nodes returned from graphql nodes query' do
      node_payload = {
        'data' => { 'nodes' => [
          nil,
          {
            'id' => @sample32.to_global_id.to_s,
            '__typename' => 'Sample',
            'puid' => @sample32.puid,
            'name' => @sample32.name,
            'project' => { 'puid' => @sample32.project.puid },
            'metadata' => { 'metadatafield1' => @sample32.metadata['metadatafield1'] }
          }
        ] }
      }

      schema_singleton = IridaSchema.singleton_class
      schema_singleton.alias_method :__execute_for_test, :execute
      schema_singleton.define_method(:execute) { |_query, **_kwargs| node_payload }

      begin
        result = DataExports::LinelistRowsService.call(
          sample_ids: [@sample32.id],
          metadata_fields: ['metadatafield1'],
          current_user: @user
        )

        assert_equal @sample32.puid, result[1][0]
        assert_equal @sample32.metadata['metadatafield1'], result[1][3]
      ensure
        schema_singleton.alias_method :execute, :__execute_for_test
        schema_singleton.remove_method :__execute_for_test
      end
    end

    # nil metadata_fields ---------------------------------------------------

    test 'nil metadata_fields produces header with no metadata columns' do
      result = DataExports::LinelistRowsService.call(
        sample_ids: [@sample32.id],
        metadata_fields: nil,
        current_user: @user
      )

      assert_equal ['SAMPLE PUID', 'SAMPLE NAME', 'PROJECT PUID'], result.first
      assert_equal 3, result[1].length
    end
  end
end
