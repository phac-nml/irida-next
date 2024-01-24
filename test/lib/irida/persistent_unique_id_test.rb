# frozen_string_literal: true

require 'test_helper'

class PersistentUniqueIdTest < ActiveSupport::TestCase
  setup do
    @old_app_prefix = Irida::PersistentUniqueId.app_prefix
  end

  teardown do
    Irida::PersistentUniqueId.app_prefix = @old_app_prefix
  end

  test 'app_prefix is configurable' do
    Irida::PersistentUniqueId.app_prefix = 'MPF'

    puid = Irida::PersistentUniqueId.generate(object_class: Sample)
    assert puid.start_with? 'MPF'
  end

  test '#generate raises error when model has no model_prefix method' do
    Irida::PersistentUniqueId.app_prefix = 'MPF'

    assert_raises Irida::PersistentUniqueId::GenerationError do
      Irida::PersistentUniqueId.generate(object_class: User)
    end
  end

  test '#generate works when model has a model_prefix method' do
    Irida::PersistentUniqueId.app_prefix = 'MPF'

    puid = Irida::PersistentUniqueId.generate(object_class: Sample)

    assert puid.start_with? "#{Irida::PersistentUniqueId.app_prefix}_#{Sample.model_prefix}_"
    assert_equal (Irida::PersistentUniqueId.app_prefix.length + Sample.model_prefix.length + 12), puid.length
  end
end
