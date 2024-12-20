# frozen_string_literal: true

require 'test_helper'

class GraphqlPolicyTest < ActiveSupport::TestCase
  def setup
    @user = users(:john_doe)
    @api_scope_token = personal_access_tokens(:john_doe_valid_pat)
    @read_api_scope_token = personal_access_tokens(:john_doe_valid_read_pat)
    @policy_with_api_scope_token = GraphqlPolicy.new(user: @user, token: @api_scope_token)
    @policy_with_read_api_scope_token = GraphqlPolicy.new(user: @user, token: @read_api_scope_token)
    @policy_without_token = GraphqlPolicy.new(user: @user, token: nil)
  end

  test '#query? when token has api scope' do
    assert @policy_with_api_scope_token.apply(:query?)
  end

  test '#mutate? when token has api scope' do
    assert @policy_with_api_scope_token.apply(:mutate?)
  end

  test '#query? when token has read api scope' do
    assert @policy_with_read_api_scope_token.apply(:query?)
  end

  test '#mutate? when token has read api scope' do
    assert_not @policy_with_read_api_scope_token.apply(:mutate?)
  end

  test '#query? when nil token' do
    assert @policy_without_token.apply(:query?)
  end

  test '#mutate? when nil token' do
    assert @policy_without_token.apply(:mutate?)
  end
end
