# frozen_string_literal: true

require 'test_helper'

class SystemFeatureFlagChangeTest < ActiveSupport::TestCase
  setup do
    @administrator = users(:system_user)
  end

  test 'validates audit fields' do
    change = SystemFeatureFlagChange.new(
      administrator: @administrator,
      feature_key: 'data_grid_samples_table',
      action: 'enable_global',
      old_global_state: 'disabled',
      new_global_state: 'enabled',
      old_opt_in_state: 'off',
      new_opt_in_state: 'off',
      environment: 'test'
    )

    assert change.valid?
  end

  test 'rejects unsupported action' do
    change = valid_change(action: 'delete_feature')

    assert_not change.valid?
    assert_includes change.errors[:action], 'is not included in the list'
  end

  test 'rejects non-admin-manageable feature keys' do
    change = valid_change(feature_key: 'compose_with_retry')

    assert_not change.valid?
    assert_includes change.errors[:feature_key], 'is invalid'
  end

  private

  def valid_change(attributes = {})
    SystemFeatureFlagChange.new(
      {
        administrator: @administrator,
        feature_key: 'data_grid_samples_table',
        action: 'enable_global',
        old_global_state: 'disabled',
        new_global_state: 'enabled',
        old_opt_in_state: 'off',
        new_opt_in_state: 'off',
        environment: 'test'
      }.merge(attributes)
    )
  end
end
