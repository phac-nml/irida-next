# frozen_string_literal: true

require 'test_helper'

class PersonalAccessTokenTest < ActiveSupport::TestCase
  def setup
    @expired_pat = personal_access_tokens(:john_doe_expired_pat)
    @non_expirable_pat = personal_access_tokens(:john_doe_non_expirable_pat)
    @revoked_pat = personal_access_tokens(:john_doe_revoked_pat)
    @valid_pat = personal_access_tokens(:john_doe_valid_pat)
  end

  test 'valid pat' do
    assert @valid_pat.valid?
  end

  test 'invalid if scopes is an empty array' do
    @valid_pat.scopes = []
    assert_not @valid_pat.valid?
  end

  test 'invalid if scopes is not in available scopes' do
    @valid_pat.scopes = ['made_up']
    assert_not @valid_pat.valid?
  end

  test 'should generate token before save' do
    pat = PersonalAccessToken.new(user: users(:john_doe), name: 'New PAT', expires_at: 1.year.from_now.to_date,
                                  scopes: ['api'])
    assert pat.save
    assert pat.token.present?
    assert pat.token_digest.present?
  end

  test '#revoke! on revoked pat doesn\'t change revoked status' do
    assert_no_changes -> { @revoked_pat.revoked? } do
      @revoked_pat.revoke!
    end
  end

  test '#revoke! on non revoked pat changes revoked status' do
    assert_changes -> { @valid_pat.revoked? } do
      @valid_pat.revoke!
    end
    assert_changes -> { @expired_pat.revoked? } do
      @expired_pat.revoke!
    end
  end

  test '#revoked? on revoked pat returns true' do
    assert @revoked_pat.revoked?
  end

  test '#revoked? on non revoked pat returns false' do
    assert_not @valid_pat.revoked?
    assert_not @expired_pat.revoked?
  end

  test '#expires? on pat with expires at returns true' do
    assert @valid_pat.expires?
    assert @expired_pat.expires?
    assert @revoked_pat.expires?
  end

  test '#expires? on pat without expires at returns false' do
    assert_not @non_expirable_pat.expires?
  end

  test '#expired? on pat with expires at in the future returns false' do
    assert_not @valid_pat.expired?
    assert_not @revoked_pat.expired?
  end

  test '#expired? on pat with expires at in the past returns true' do
    assert @expired_pat.expired?
  end

  test '#expired? on pat without expires at returns false' do
    assert_not @non_expirable_pat.expired?
  end

  test '#active? on pat that is not revoked or expired returns true' do
    assert @valid_pat.active?
    assert @non_expirable_pat.active?
  end

  test '#active? on pat that is expired or revoked returns false' do
    assert_not @revoked_pat.active?
    assert_not @expired_pat.active?
  end

  test '#find_by_token' do
    assert_equal @valid_pat, PersonalAccessToken.find_by_token('JQ2w5maQc4zgvC8GGMEp') # rubocop:disable Rails/DynamicFindBy
  end
end
