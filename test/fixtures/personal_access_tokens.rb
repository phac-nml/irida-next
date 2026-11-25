# frozen_string_literal: true

FixtureBot.define do
  personal_access_token :john_doe_expired_pat do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    scopes %w[api]
    name 'Expired PAT'
    revoked false
    expires_at '<%= Irida::CurrentSettings.current_application_settings.cleanup_inactive_access_tokens_after_days.days.ago.to_date %>' # rubocop:disable Layout/LineLength
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'byb8myzkJ7HNeFS2La-8')
    last_used_at nil
  end

  personal_access_token :john_doe_revoked_pat do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    scopes %w[api]
    name 'Revoked PAT'
    revoked true
    expires_at '<%= 10.days.from_now.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'osvR7Re6ZN_7sem8wF9z')
    last_used_at nil
    updated_at '<%= 31.days.ago %>'
  end

  personal_access_token :john_doe_valid_pat do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    scopes %w[api]
    name 'Valid PAT'
    revoked false
    expires_at '<%= 10.days.from_now.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'JQ2w5maQc4zgvC8GGMEp')
    last_used_at nil
  end

  personal_access_token :john_doe_valid_read_pat do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    scopes %w[read_api]
    name 'Valid PAT'
    revoked false
    expires_at '<%= 10.days.from_now.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'X83wwK3sWCjn4xdCyZtH')
    last_used_at nil
  end

  personal_access_token :john_doe_non_expirable_pat do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    scopes %w[api]
    name 'Non Expirable PAT'
    revoked false
    expires_at nil
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'b8rH5_yCXFi-fxirkvfz')
    last_used_at nil
  end

  personal_access_token :john_doe_valid_pat_used do
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
    scopes %w[api]
    name 'Valid PAT'
    revoked false
    expires_at '<%= 10.days.from_now.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'JQ2w5maQc4zgvC8GGMEr')
    last_used_at '<%= 1.day.ago %>'
    last_used_ips ['192.168.1.2', '192.168.1.1']
  end

  personal_access_token :jane_doe_valid_pat do
    user_id ActiveRecord::FixtureSet.identify(:jane_doe, :uuid)
    scopes %w[api]
    name 'Valid PAT'
    revoked false
    expires_at '<%= 10.days.from_now.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'MMx_KskxBCx9tpc5qusm')
    last_used_at nil
  end

  personal_access_token :jeff_doe_valid_pat do
    user_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    scopes %w[api]
    name 'Valid PAT'
    revoked false
    expires_at '<%= 10.days.from_now.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'JX2w5maQc4zgvC8GGMEp')
    last_used_at nil
  end

  personal_access_token :jeff_doe_valid_read_pat do
    user_id ActiveRecord::FixtureSet.identify(:jeff_doe, :uuid)
    scopes %w[read_api]
    name 'Valid PAT'
    revoked false
    expires_at '<%= 10.days.from_now.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'XX3wwK3sWCjn4xdCyZtH')
    last_used_at nil
  end

  22.times do |n|
    personal_access_token :"user_bot_account#{n}_valid_pat" do
      user_id ActiveRecord::FixtureSet.identify(:"user_bot_account#{n}", :uuid)
      scopes %w[read_api api]
      name "Valid PAT#{n}"
      revoked false
      expires_at '<%= 10.days.from_now.to_date %>'
      token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, "DX3wwK3sWCjn#{n}xdCyZtH")
      last_used_at nil
    end
  end

  21.times do |n|
    personal_access_token :"user_group_bot_account#{n}_valid_pat" do
      user_id ActiveRecord::FixtureSet.identify(:"user_group_bot_account#{n}", :uuid)
      scopes %w[read_api api]
      name "Valid PAT#{n}"
      revoked false
      expires_at '<%= 10.days.from_now.to_date %>'
      token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, "AX3wwK3sWCjn#{n}xdCyZtH")
      last_used_at nil
    end
  end

  personal_access_token :projectJeff_bot_account_valid_pat do
    user_id ActiveRecord::FixtureSet.identify(:projectJeff_bot, :uuid)
    scopes %w[read_api api]
    # NOTE: reproduces a pre-existing typo in the original fixture, where a stray
    # "1 %>" (leftover from an unclosed ERB tag) ends up as part of the literal name.
    name 'Valid PAT1 %>'
    revoked false
    expires_at '<%= 10.days.from_now.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'FX3wwK3sWCjn1xdCyZtA')
    last_used_at nil
  end

  personal_access_token :groupJeff_bot_account_valid_pat do
    user_id ActiveRecord::FixtureSet.identify(:groupJeff_bot, :uuid)
    scopes %w[read_api api]
    name 'Valid PAT1 %>'
    revoked false
    expires_at '<%= 10.days.from_now.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'FX3wwK3sWCjn1xdCyZtB')
    last_used_at nil
  end

  personal_access_token :user_bot_account0_expired_pat do
    user_id ActiveRecord::FixtureSet.identify(:user_bot_account0, :uuid)
    scopes %w[read_api api]
    name 'Expired Valid PAT0'
    revoked false
    expires_at '<%= 10.days.ago.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'VX3wwK3sWCjn0xdCyZtH')
    last_used_at nil
  end

  personal_access_token :user_group_bot_account0_expired_pat do
    user_id ActiveRecord::FixtureSet.identify(:user_group_bot_account0, :uuid)
    scopes %w[read_api api]
    name 'Expired PAT 0'
    revoked false
    expires_at '<%= 5.days.ago.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'TA3wwK3sWCjn0xdCyZtH')
    last_used_at nil
  end

  personal_access_token :user_bot_account0_revoked_pat do
    user_id ActiveRecord::FixtureSet.identify(:user_bot_account0, :uuid)
    scopes %w[read_api api]
    name 'Revoked Valid PAT0'
    revoked true
    expires_at '<%= 10.days.ago.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'VX3wwK3sWTjn0xdCyZtH')
    last_used_at nil
    updated_at '<%= 31.days.ago %>'
  end

  personal_access_token :user_group_bot_account0_revoked_pat do
    user_id ActiveRecord::FixtureSet.identify(:user_group_bot_account0, :uuid)
    scopes %w[read_api api]
    name 'Revoked PAT 0'
    revoked true
    expires_at '<%= 5.days.ago.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'TA3wwK3sWCjr0xdCyZtH')
    last_used_at nil
    updated_at '<%= 29.days.ago %>'
  end

  personal_access_token :sample_actions_doe_valid_pat do
    user_id ActiveRecord::FixtureSet.identify(:sample_actions_doe, :uuid)
    scopes %w[api]
    name 'Valid PAT'
    revoked false
    expires_at '<%= 10.days.from_now.to_date %>'
    token_digest Devise.token_generator.digest(PersonalAccessToken, :token_digest, 'JQ2w5maQc4zgvC8GGMEq')
    last_used_at nil
  end
end
