# frozen_string_literal: true

require 'test_helper'

class DataExportTest < ActiveSupport::TestCase
  def setup
    @export1 = data_exports(:data_export_one)
    @attachment = attachments(:attachment1)
  end

  test 'valid data export' do
    assert @export1.valid?
  end

  test 'export attachment' do
    assert_equal 'data_export_1.zip', @export1.file.filename
  end
end
