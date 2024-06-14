# frozen_string_literal: true

require 'test_helper'

class PuidQueryTest < ActiveSupport::TestCase
  PUID_QUERY_TRUE = <<~GRAPHQL
    query {
      isPuid(id: "INXT_SAM_23F24BP6A7")
    }
  GRAPHQL

  PUID_QUERY_FALSE = <<~GRAPHQL
    query {
      isPuid(id: "INXT_SAM_23D56SE3M8")
    }
  GRAPHQL

  def setup
    @user = users(:john_doe)
  end

  test 'is puid query should return true' do
    result = IridaSchema.execute(PUID_QUERY_TRUE, context: { current_user: @user }, variables: {})

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']

    assert_not_empty data, 'puid type should work'
    assert data['isPuid']
  end

  test 'is puid query should return false' do
    result = IridaSchema.execute(PUID_QUERY_FALSE, context: { current_user: @user }, variables: {})

    assert_nil result['errors'], 'should work and have no errors.'

    data = result['data']

    assert_not_empty data, 'puid type should work'
    assert_not data['isPuid']
  end
end
