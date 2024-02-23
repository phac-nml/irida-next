# frozen_string_literal: true

require 'test_helper'

class DataExportTest < ActiveSupport::TestCase
  def setup
    @export1 = data_exports(:data_export_one)
  end

  test 'valid data export' do
    assert @export1.valid?
  end
end
