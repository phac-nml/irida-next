# frozen_string_literal: true

require 'test_helper'

class PersonalAccessTokensTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  def setup
    @user = users(:john_doe)
    sign_in @user
  end

  test 'should get index' do
    get profile_personal_access_tokens_path

    assert_response :success

    card_counts = {
      active_tokens: @user.personal_access_tokens.active.count,
      expired_tokens: @user.personal_access_tokens.expired.count,
      revoked_tokens: @user.personal_access_tokens.revoked.count,
      expiring_tokens: @user.personal_access_tokens.expiring_in_two_weeks.count
    }

    card_counts.each do |card, count|
      assert_select 'h3', text: I18n.t("personal_access_tokens.information_component.#{card}"), count: 1
      assert_select 'div[aria-describedby^="statistic-label-"]', text: /\A\s*#{count}\s*\z/, minimum: 1
    end

    assert_select 'div[aria-describedby^="statistic-label-"]', count: card_counts.size

    @user.personal_access_tokens.active.each do |token|
      assert_select '#access-tokens-table', text: /#{Regexp.escape(token.name)}/
    end
  end

  test 'can view last used IP of personal access tokens' do
    not_used_pat = personal_access_tokens(:john_doe_non_expirable_pat)
    used_pat = personal_access_tokens(:john_doe_valid_pat_used)

    get profile_personal_access_tokens_path

    assert_response :success
    assert_select "tr#personal_access_token_#{not_used_pat.id} td:nth-child(6)",
                  text: I18n.t('personal_access_tokens.table.never_used')
    assert_select "tr#personal_access_token_#{used_pat.id} td:nth-child(6)", text: /192\.168\.1\.1/
  end

  test 'shows the empty personal access tokens state' do
    sign_out @user
    sign_in users(:empty_doe)

    get profile_personal_access_tokens_path

    assert_response :success
    assert_select '#access-tokens-table', count: 0
    assert_select '.empty_state_message', text: /#{Regexp.escape(
      I18n.t('profiles.personal_access_tokens.table.empty_state.active.title')
    )}/
    assert_select '.empty_state_message', text: /#{Regexp.escape(
      I18n.t('profiles.personal_access_tokens.table.empty_state.active.description')
    )}/
  end

  test 'should list active tokens' do
    get list_profile_personal_access_tokens_path(type: :active, format: :turbo_stream)

    assert_response :success
    assert_select 'span.token-status', count: @user.personal_access_tokens.active.count
  end

  test 'should list revoked tokens' do
    get list_profile_personal_access_tokens_path(type: :revoked, format: :turbo_stream)

    assert_response :success
    assert_select 'span.token-status', count: @user.personal_access_tokens.revoked.count
    assert_select 'button', text: I18n.t(:'personal_access_tokens.table.rotate'), count: 0
  end

  test 'should list expired tokens' do
    get list_profile_personal_access_tokens_path(type: :expired, format: :turbo_stream)

    assert_response :success
    assert_select 'span.token-status', count: @user.personal_access_tokens.expired.count
    assert_select 'button', text: I18n.t(:'personal_access_tokens.table.rotate'), count: 0
  end

  test 'should list expiring tokens' do
    get list_profile_personal_access_tokens_path(type: :expiring, format: :turbo_stream)

    assert_response :success
    assert_select 'span.token-status', count: @user.personal_access_tokens.expiring_in_two_weeks.count
  end

  test 'should get new' do
    get new_profile_personal_access_token_path(format: :turbo_stream)

    assert_response :success
    assert_select 'form[action="/-/profile/personal_access_tokens"]' do
      assert_select 'input[name="personal_access_token[name]"]', count: 1
      assert_select 'input#personal_access_token_scopes_api', count: 1
      assert_select 'button[type="submit"]',
                    text: I18n.t(:'profiles.personal_access_tokens.create.submit'),
                    count: 1
    end
  end

  test 'should create personal access token' do
    token_name = 'my new token'
    assert_difference(-> { @user.personal_access_tokens.count } => 1) do
      post profile_personal_access_tokens_path(format: :turbo_stream),
           params: { personal_access_token: { name: token_name, scopes: ['api'] } }
    end

    assert_response :success
    assert_select "div[data-viral--flash-type-value='success']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.success')}: #{I18n.t(
                      'profiles.personal_access_tokens.create.success',
                      name: token_name
                    )}"
    end
    assert_select 'span.token-status', count: @user.personal_access_tokens.active.count
  end

  test 'cannot create personal access token without expiration date if require_personal_access_token_expiry is set' do
    settings = Irida::CurrentSettings.current_application_settings
    previous_require_expiry = settings.require_personal_access_token_expiry
    settings.update!(require_personal_access_token_expiry: true)

    begin
      assert_no_difference(-> { @user.personal_access_tokens.count }) do
        post profile_personal_access_tokens_path(format: :turbo_stream),
             params: { personal_access_token: { name: 'my new token', scopes: ['api'] } }
      end

      assert_response :unprocessable_content
      assert_select 'form[action="/-/profile/personal_access_tokens"]' do
        assert_select '[data-controller="form-error-summary"]' do
          assert_select 'a', text:
                 I18n.t(:'errors.format',
                        attribute: I18n.t(:'activerecord.attributes.personal_access_token.expires_at'),
                        message: I18n.t(:'common.date.errors.invalid_input'))
        end
        assert_select 'input[name="personal_access_token[expires_at]"]', focused: true
      end
    ensure
      settings.update!(require_personal_access_token_expiry: previous_require_expiry)
    end
  end

  test 'should not create personal access token without scopes' do
    assert_no_difference(-> { @user.personal_access_tokens.count }) do
      post profile_personal_access_tokens_path(format: :turbo_stream),
           params: { personal_access_token: { name: 'token' } }
    end

    assert_response :unprocessable_content
    assert_select 'form[action="/-/profile/personal_access_tokens"]' do
      assert_select 'div[data-controller="form-error-summary"]' do
        assert_select 'a', text:
               I18n.t(:'errors.format',
                      attribute: I18n.t(:'activerecord.attributes.personal_access_token.scopes'),
                      message: I18n.t(:'errors.messages.blank'))
      end
      assert_select 'input[name="personal_access_token[scopes][]"]', focused: true
    end
  end

  test 'should not create personal access token with invalid scopes' do
    assert_no_difference(-> { @user.personal_access_tokens.count }) do
      post profile_personal_access_tokens_path(format: :turbo_stream),
           params: { personal_access_token: { name: 'token', scopes: ['write_api'] } }
    end

    assert_response :unprocessable_content
    assert_select 'form[action="/-/profile/personal_access_tokens"]' do
      assert_select 'div[data-controller="form-error-summary"]' do
        assert_select 'a', text:
               I18n.t(:'errors.format',
                      attribute: I18n.t(:'activerecord.attributes.personal_access_token.scopes'),
                      message: I18n.t(:'errors.messages.inclusion'))
      end
      assert_select 'input[name="personal_access_token[scopes][]"]', focused: true
    end
  end

  test 'should display base errors when personal access token creation fails' do
    token_with_errors = PersonalAccessToken.new
    token_with_errors.errors.add(:base, 'Creation failed')
    create_service = mock('create_service')
    create_service.stubs(:execute).returns(token_with_errors)
    PersonalAccessTokens::CreateService.expects(:new).returns(create_service)
    Profiles::PersonalAccessTokensController.any_instance.expects(:error_message)
                                            .with(token_with_errors).returns('Creation failed')

    assert_no_difference(-> { @user.personal_access_tokens.count }) do
      post profile_personal_access_tokens_path(format: :turbo_stream),
           params: { personal_access_token: { name: 'token', scopes: ['api'] } }
    end

    assert_response :unprocessable_content
    assert_select "div[data-viral--flash-type-value='error']" do
      assert_select 'div', "#{I18n.t('common.statuses.error')}: Creation failed"
    end
  end

  test 'should revoke personal access token' do
    token = personal_access_tokens(:john_doe_valid_pat)

    assert_changes -> { token.reload.revoked? }, from: false, to: true do
      delete revoke_profile_personal_access_token_path(id: token, format: :turbo_stream)
    end

    assert_response :success
    assert_select '[data-viral--flash-type-value="success"]',
                  text: /Personal access token.*#{Regexp.escape(token.name)}.*successfully revoked\./
    assert_select '#access-tokens-table', text: /#{Regexp.escape(token.name)}/, count: 0
  end

  test 'should not revoke personal access token for another user' do
    assert_no_changes -> { personal_access_tokens(:jane_doe_valid_pat).reload.revoked? } do
      delete revoke_profile_personal_access_token_path(id: personal_access_tokens(:jane_doe_valid_pat),
                                                       format: :turbo_stream)
    end

    assert_response :not_found
  end

  test 'should rotate personal access token' do
    token = personal_access_tokens(:john_doe_valid_pat)

    assert_difference(-> { @user.personal_access_tokens.count } => 1) do
      assert_changes -> { token.reload.revoked? }, from: false, to: true do
        put rotate_profile_personal_access_token_path(id: token, format: :turbo_stream)
      end
    end

    assert_response :success
    assert_select '[data-controller="token"]' do
      assert_select 'button[data-action="click->token#copyToClipboard"]', count: 1
    end
    assert_select '#access-tokens-table', text: /#{Regexp.escape(token.name)}/
  end

  test 'should not rotate expired personal access token' do
    token = personal_access_tokens(:john_doe_expired_pat)

    assert_no_difference(-> { @user.personal_access_tokens.count }) do
      assert_no_changes -> { token.reload.revoked? } do
        put rotate_profile_personal_access_token_path(id: token, format: :turbo_stream)
      end
    end

    assert_response :unprocessable_entity
    assert_select "div[data-viral--flash-type-value='error']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.error')}: #{I18n.t(
                      'activerecord.errors.models.personal_access_tokens.rotate.only_active'
                    )}"
    end
  end

  test 'should not rotate revoked personal access token' do
    token = personal_access_tokens(:john_doe_revoked_pat)

    assert_no_difference(-> { @user.personal_access_tokens.count }) do
      assert_no_changes -> { token.reload.revoked? } do
        put rotate_profile_personal_access_token_path(id: token, format: :turbo_stream)
      end
    end

    assert_response :unprocessable_entity
    assert_select "div[data-viral--flash-type-value='error']" do
      assert_select 'div',
                    "#{I18n.t('common.statuses.error')}: #{I18n.t(
                      'activerecord.errors.models.personal_access_tokens.rotate.only_active'
                    )}"
    end
  end
end
