# frozen_string_literal: true

require 'test_helper'

class DataExportTest < ActiveSupport::TestCase
  def setup
    @export1 = data_exports(:data_export_one)
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
    data_export = DataExport.new(user: @user, status: 'invalid status', export_type: 'sample')
    assert_not data_export.valid?
    data_export.status = 'processing'
    assert data_export.valid?
  end

  test 'data export with invalid export_type' do
    data_export = DataExport.new(user: @user, status: 'ready', export_type: 'invalid type')
    assert_not data_export.valid?
    data_export.export_type = 'analysis'
    assert data_export.valid?
  end

  test '#destroy removes export' do
    assert_difference(-> { DataExport.count } => -1) do
      @export1.destroy
    end
  end

  test '#destroy removes export, then is restored' do
    assert_difference(-> { DataExport.count } => -1) do
      @export1.destroy
    end

    assert_difference(-> { DataExport.count } => +1) do
      DataExport.restore(@export1.id, recursive: true)
    end
  end
end
