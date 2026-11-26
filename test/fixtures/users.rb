# frozen_string_literal: true

FixtureBot.define do
  user.last_name { 'Doe' }

  # Mirrors the original YAML's `DEFAULTS: &DEFAULTS` anchor/merge-key, applied to every
  # record below unless explicitly overridden. `encrypted_password` is kept as a literal
  # ERB tag (rather than computed here) because BCrypt salts the hash randomly on every
  # call -- computing it at *compile* time would make the compiled YAML change on every
  # recompile. Evaluating it via Rails' real ERB pass at fixture-load time instead
  # reproduces the original fixtures' behaviour of hashing "password1" fresh every run.
  user.encrypted_password { '<%= User.new.send(:password_digest, "password1") %>' }
  user.locale { 'en' }
  user.user_type { 'human' }

  user :system_user do
    email 'system@localhost'
    first_name 'System'
    last_name 'User'
    system true
  end

  user :john_doe do
    email 'john.doe@localhost'
    first_name 'John'
  end

  user :jane_doe do
    email 'jane.doe@localhost'
    first_name 'Jane'
  end

  user :jean_doe do
    email 'jean.doe@localhost'
    first_name 'Jean'
  end

  user :james_doe do
    email 'james.doe@localhost'
    first_name 'James'
    locale 'fr'
  end

  user :joan_doe do
    email 'joan.doe@localhost'
    first_name 'Joan'
    locale 'fr'
  end

  user :steve_doe do
    email 'steve.doe@localhost'
    first_name 'Steve'
  end

  user :michelle_doe do
    email 'michelle.doe@localhost'
    first_name 'Michelle'
  end

  user :micha_doe do
    email 'micha.doe@localhost'
    first_name 'Micha'
  end

  user :ryan_doe do
    email 'ryan.doe@localhost'
    first_name 'Ryan'
  end

  user :david_doe do
    email 'david.doe@localhost'
    first_name 'David'
  end

  user :jeff_doe do
    email 'jeff.doe@localhost'
    first_name 'Jeff'
    provider 'developer'
    uid 'jeff.doe@localhost'
  end

  user :alph_abet do
    email 'alph.abet@localhost'
    first_name 'Alph'
    last_name 'Abet'
  end

  25.times do |n|
    user(:"user#{n}") do
      email "user#{n}@localhost"
      first_name 'User'
      last_name n
    end
  end

  user :user25 do
    email 'user25@localhost'
    first_name 'User'
    last_name '25'
  end

  # Do not link this user to anything
  user :user_no_access do
    email 'user_no_access@localhost'
    first_name 'User'
    last_name 'No Access'
  end

  user :private_ryan do
    email 'private.ryan@localhost'
    first_name 'Private'
    last_name 'Ryan'
  end

  user :user26 do
    email 'user26@localhost'
    first_name 'User'
    last_name '26'
  end

  user :private_joan do
    email 'private.joan@localhost'
    first_name 'Private'
    last_name 'Joan'
  end

  user :private_micha do
    email 'private.micha@localhost'
    first_name 'Private'
    last_name 'Micha'
  end

  user :user27 do
    email 'user27@localhost'
    first_name 'User'
    last_name '27'
  end

  user :user28 do
    email 'user28@localhost'
    first_name 'User'
    last_name '28'
  end

  22.times do |n|
    user(:"user_bot_account#{n}") do
      email "inxt_prj_aaaaaaaaaa_bot_#{format('%03d', n + 1)}@localhost"
      first_name 'Project'
      # Faithfully reproduces the original fixture: `#{...}` here was written inside a
      # plain double-quoted YAML scalar (not an ERB tag), so it was never evaluated --
      # every row in this loop actually has this identical literal last_name in the DB.
      last_name "Bot \#{format('%03d', (n + 1))}"
      user_type User.user_types[:project_bot]
    end
  end

  user :user29 do
    email 'user29@localhost'
    first_name 'User'
    last_name '29'
  end

  user :user30 do
    email 'user30@localhost'
    first_name 'User'
    last_name '30'
  end

  user :user31 do
    email 'user31@localhost'
    first_name 'User'
    last_name '31'
  end

  user :user32 do
    email 'user32@localhost'
    first_name 'User'
    last_name '32'
  end

  22.times do |n|
    user(:"user_group_bot_account#{n}") do
      email "inxt_grp_aaaaaaaaaa_bot#{format('%03d', n + 1)}@localhost"
      first_name 'Group'
      # Faithfully reproduces the original fixture: `#{...}` here was written inside a
      # plain double-quoted YAML scalar (not an ERB tag), so it was never evaluated --
      # every row in this loop actually has this identical literal last_name in the DB.
      last_name "Bot \#{format('%03d', (n + 1))}"
      user_type User.user_types[:group_bot]
    end
  end

  user :project1_automation_bot do
    email 'inxt_prj_aaaaaaaaaa_automation_bot@localhost'
    first_name 'INXT_PRJ_AAAAAAAAAA'
    last_name 'Automation Bot'
    user_type User.user_types[:project_automation_bot]
  end

  user :projectA_automation_bot do
    email 'inxt_prj_aaaaaaaaa5_automation_bot@localhost'
    first_name 'INXT_PRJ_AAAAAAAAA5'
    last_name 'Automation Bot'
    user_type User.user_types[:project_automation_bot]
  end

  user :janitor_doe do
    email 'janitor_doe@localhost'
    first_name 'project'
    last_name 'end to end user'
  end

  user :projectJeff_bot do
    email 'inxt_prj_aaaaaaaabp_001@localhost'
    first_name 'INXT_PRJ_AAAAAAAABP'
    last_name 'Bot'
    user_type User.user_types[:project_bot]
  end

  user :groupJeff_bot do
    email 'inxt_grp_aaaaaajeff_001@localhost'
    first_name 'INXT_GRP_AAAAAAJEFF'
    last_name 'Bot'
    user_type User.user_types[:group_bot]
  end

  user :empty_doe do
    email 'empty_doe@localhost'
    first_name 'Empty'
  end

  user :metadata_doe do
    email 'metadata_doe@localhost'
    first_name 'Metadata'
  end

  user :mary_doe do
    email 'mary.doe@localhost'
    first_name 'Mary'
  end

  user :sample_actions_doe do
    email 'sample.actions.doe@localhost'
    first_name 'SampleActions'
  end

  user :shared_sample_actions_doe do
    email 'shared.sample.actions.doe@localhost'
    first_name 'SharedSampleActions'
  end

  user :subgroup_sample_actions_doe do
    email 'subgroup.sample.actions.doe@localhost'
    first_name 'SubgroupSampleActions'
  end

  user :chunked_samples_doe do
    email 'chunked.samples.doe@localhost'
    first_name 'ChunkedSamples'
  end

  user :snvphyl_user do
    email 'snvphyl.user@localhost'
    first_name 'SNVPhyl'
    last_name 'User'
  end

  user :clone_test_maintainer_one do
    email 'clone.test.maintainer.one@localhost'
    first_name 'CloneTestMaintainer'
    last_name 'One'
  end

  user :clone_test_maintainer_two do
    email 'clone.test.maintainer.two@localhost'
    first_name 'CloneTestMaintainer'
    last_name 'Two'
  end
end
