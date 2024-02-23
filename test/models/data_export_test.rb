# frozen_string_literal: true

require 'test_helper'

class DataExportTest < ActiveSupport::TestCase
  def setup
    @export1 = data_exports(:data_export_one)
    @attachment = attachments(:attachment1)
  end

  test 'valid data export' do
    assert_equal @export1.file, 'data_export_1.zip'
  end
end
