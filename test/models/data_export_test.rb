# frozen_string_literal: true

require 'test_helper'

class DataExportTest < ActiveSupport::TestCase
  def setup
    @export1 = data_exports(:data_export_one)
    @sample1 = samples(:sample1)
    @user = users(:john_doe)
  end

  test 'valid data export' do
    assert @export1.valid?
  end

  test 'attach zip to export' do
    @export1.file.attach(io: Rails.root.join('test/fixtures/files/data_export_1.zip').open,
                         filename: 'data_export_1.zip')
    @export1.save
    assert_equal 'data_export_1.zip', @export1.file.filename.to_s
  end

  test 'data export with invalid status' do
    data_export = DataExport.new(user: @user, status: 'invalid status', export_type: 'sample',
                                 export_parameters: { ids: [@sample1.id] })
    assert_not data_export.valid?
    data_export.status = 'processing'
    assert data_export.valid?
  end

  test 'data export with invalid export_type' do
    data_export = DataExport.new(user: @user, status: 'ready', export_type: 'invalid type',
                                 export_parameters: { ids: [@sample1.id] })
    assert_not data_export.valid?
    data_export.export_type = 'analysis'
    assert data_export.valid?
  end

  test '#destroy removes export' do
    assert_difference(-> { DataExport.count } => -1) do
      @export1.destroy
    end
  end

  test 'export with missing ids' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'analysis',
                                 export_parameters: { not_ids: [@sample1.id] })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_ids'),
                 data_export.errors[:export_parameters].first
  end

  test 'linelist export with missing metadata fields' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id], format: 'xlsx',
                                                      namespace_type: Namespaces::ProjectNamespace.sti_name })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_metadata_fields'),
                 data_export.errors[:export_parameters].first
  end

  test 'linelist export with missing namespace_type' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id], format: 'xlsx',
                                                      metadata_fields: ['a_metadata_field'] })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_namespace_type'),
                 data_export.errors[:export_parameters].first
  end

  test 'linelist export with invalid namespace_type' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id], format: 'csv',
                                                      metadata_fields: ['a_metadata_field'],
                                                      namespace_type: 'invalid_namespace_type' })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_namespace_type'),
                 data_export.errors[:export_parameters].first
  end

  test 'linelist export with missing format' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id],
                                                      metadata_fields: ['a_metadata_field'],
                                                      namespace_type: Group.sti_name })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.missing_file_format'),
                 data_export.errors[:export_parameters].first
  end

  test 'linelist export with invalid format' do
    data_export = DataExport.new(user: @user, status: 'processing', export_type: 'linelist',
                                 export_parameters: { ids: [@sample1.id], format: 'invalid_format',
                                                      metadata_fields: ['a_metadata_field'],
                                                      namespace_type: Group.sti_name })
    assert_not data_export.valid?
    assert_equal I18n.t('activerecord.errors.models.data_export.attributes.export_parameters.invalid_file_format'),
                 data_export.errors[:export_parameters].first
  end
end
