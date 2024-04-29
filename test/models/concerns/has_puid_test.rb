# frozen_string_literal: true

require 'test_helper'

class HasPuidTest < ActionDispatch::IntegrationTest
  def setup
    @project = projects(:project1)
    @sample = samples(:sample1)
  end

  test 'generate_puid' do
    puid = @sample.puid

    @sample.generate_puid
    assert_equal puid, @sample.puid

    sample = Sample.new

    assert_nil sample.puid
    sample.generate_puid
    assert sample.puid
  end

  test 'model_prefix' do
    assert_nothing_raised do
      Sample.model_prefix
    end

    assert_raises(NotImplementedError) do
      Namespace.model_prefix
    end
  end

  test 'dup' do
    clone = @sample.dup

    assert @sample.puid
    assert_nil clone.puid
  end
end
