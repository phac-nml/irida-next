# frozen_string_literal: true

require 'test_helper'

class MetadataHelperTest < ActionView::TestCase
  include MetadataHelper

  test 'should flatten hash' do
    h = {
      x: 0,
      y: { x: 1 },
      z: [
        {
          y: 0,
          x: 2
        },
        4
      ]
    }
    flat_h = {
      'x' => 0,
      'y.x' => 1,
      'z.0.y' => 0,
      'z.0.x' => 2,
      'z.1' => 4
    }

    assert_equal flat_h, flatten(h)
  end

  test 'flat hash should stay flat' do
    h = {
      x: 0,
      y: '1'
    }
    flat_h = {
      'x' => 0,
      'y' => '1'
    }

    assert_equal flat_h, flatten(h)
  end

  test 'should flatten complex hash' do
    h = {
      x: 0,
      y: {
        x: 1,
        y: [
          1,
          2
        ],
        z: {
          x: 1
        }
      },
      z: [
        {
          y: 0,
          x: 2
        },
        4
      ]
    }
    flat_h = {
      'x' => 0,
      'y.x' => 1,
      'y.y.0' => 1,
      'y.y.1' => 2,
      'y.z.x' => 1,
      'z.0.y' => 0,
      'z.0.x' => 2,
      'z.1' => 4
    }

    assert_equal flat_h, flatten(h)
  end
end
