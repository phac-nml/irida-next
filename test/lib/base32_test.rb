# frozen_string_literal: true

require 'test_helper'

class Base32Test < ActiveSupport::TestCase
  test '#encode32 with nil length returns nil' do
    assert_nil Base32.encode32(0, nil)
  end

  test '#encode32 with length = 0 returns nil' do
    assert_nil Base32.encode32(0, 0)
  end

  test '#encode32 with nil number returns nil' do
    assert_nil Base32.encode32(nil, 1)
  end

  test '#encode32 with negative number returns nil' do
    assert_nil Base32.encode32(-12, 1)
  end

  test '#encode32 with zero number returns a base32 string' do
    assert 'A', Base32.encode32(0, 1)
  end

  test '#encode32 with positive number returns a base32 string' do
    assert 'M', Base32.encode32(12, 1)
  end

  test '#encode32 with number not encodable in the length provided raise EncodingError' do
    assert_raises Base32::EncodingError do
      Base32.encode32(32, 1)
    end
  end
end
