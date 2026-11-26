# frozen_string_literal: true

FixtureBot.define do
  namespaces_user_namespace.type { 'User' }

  namespaces_user_namespace :john_doe_namespace do
    name 'john.doe@localhost'
    path 'john.doe_at_localhost'
    owner :john_doe
    puid 'INXT_USR_AAAAAAAAAA'
  end

  namespaces_user_namespace :jane_doe_namespace do
    name 'jane.doe@localhost'
    path 'jane.doe_at_localhost'
    owner :jane_doe
    puid 'INXT_USR_AAAAAAAAAB'
  end

  namespaces_user_namespace :jean_doe_namespace do
    name 'jean.doe@localhost'
    path 'jean.doe_at_localhost'
    owner :jean_doe
    puid 'INXT_USR_AAAAAAAAAC'
  end

  namespaces_user_namespace :james_doe_namespace do
    name 'james.doe@localhost'
    path 'james.doe_at_localhost'
    owner :james_doe
    puid 'INXT_USR_AAAAAAAAAD'
  end

  namespaces_user_namespace :david_doe_namespace do
    name 'david.doe@localhost'
    path 'david.doe_at_localhost'
    owner :david_doe
    puid 'INXT_USR_AAAAAAAAAE'
  end

  namespaces_user_namespace :jeff_doe_namespace do
    name 'jeff.doe@localhost'
    path 'jeff.doe_at_localhost'
    owner :jeff_doe
    puid 'INXT_USR_AAAAAAAAAF'
  end

  namespaces_user_namespace :private_ryan_namespace do
    name 'private.ryan@localhost'
    path 'private.ryan_at_localhost'
    owner :private_ryan
    puid 'INXT_USR_AAAAAAAAAG'
  end

  namespaces_user_namespace :joan_doe_namespace do
    name 'joan.doe@localhost'
    path 'joan.doe_at_localhost'
    owner :joan_doe
    puid 'INXT_USR_AAAAAAAAAH'
  end

  namespaces_user_namespace :micha_doe_namespace do
    name 'micha.doe@localhost'
    path 'micha.doe_at_localhost'
    owner :micha_doe
    puid 'INXT_USR_AAAAAAAAAI'
  end

  namespaces_user_namespace :ryan_doe_namespace do
    name 'ryan.doe@localhost'
    path 'ryan.doe_at_localhost'
    owner :ryan_doe
    puid 'INXT_USR_AAAAAAAAAJ'
  end

  namespaces_user_namespace :user_25_namespace do
    name 'user.25@localhost'
    path 'user.25_at_localhost'
    owner :user25
    puid 'INXT_USR_AAAAAAAAZK'
  end

  namespaces_user_namespace :user_26_namespace do
    name 'user.26@localhost'
    path 'user.26_at_localhost'
    owner :user26
    puid 'INXT_USR_AAAAAAAAAK'
  end

  namespaces_user_namespace :alph_abet_namespace do
    name 'alph.abet@localhost'
    path 'alph.abet_at_localhost'
    owner :alph_abet
    puid 'INXT_USR_AAAAAAAAAL'
  end

  namespaces_user_namespace :private_joan_namespace do
    name 'private.joan@localhost'
    path 'private.joan_at_localhost'
    owner :private_joan
    puid 'INXT_USR_AAAAAAAAAM'
  end

  namespaces_user_namespace :private_micha_namespace do
    name 'private.micha@localhost'
    path 'private.micha_at_localhost'
    owner :private_micha
    puid 'INXT_USR_AAAAAAAAAN'
  end

  namespaces_user_namespace :user27_namespace do
    name 'user.27@localhost'
    path 'user.27_at_localhost'
    owner :user27
    puid 'INXT_USR_AAAAAAAAAO'
  end

  namespaces_user_namespace :user28_namespace do
    name 'user.28@localhost'
    path 'user.28_at_localhost'
    owner :user28
    puid 'INXT_USR_AAAAAAAAAP'
  end

  namespaces_user_namespace :user29_namespace do
    name 'user.29@localhost'
    path 'user.29_at_localhost'
    owner :user29
    puid 'INXT_USR_AAAAAAAAAQ'
  end

  namespaces_user_namespace :user30_namespace do
    name 'user.30@localhost'
    path 'user.30_at_localhost'
    owner :user30
    puid 'INXT_USR_AAAAAAAAAR'
  end

  namespaces_user_namespace :user32_namespace do
    name 'user.32@localhost'
    path 'user.32_at_localhost'
    owner :user32
    puid 'INXT_USR_AAAAAAAZZR'
  end

  namespaces_user_namespace :metadata_doe_namespace do
    name 'metadata.doe@localhost'
    path 'metadata.doe_at_localhost'
    owner :metadata_doe
    puid 'INXT_USR_AAAAAAAAAS'
  end

  namespaces_user_namespace :mary_doe_namespace do
    name 'mary.doe@localhost'
    path 'mary.doe_at_localhost'
    owner :mary_doe
    puid 'INXT_USR_AAAAAAAAAT'
  end

  namespaces_user_namespace :sample_actions_doe_namespace do
    name 'sample.actions.doe@localhost'
    path 'sample.actions.doe_at_localhost'
    owner :sample_actions_doe
    puid 'INXT_USR_AAAAAAAAAU'
  end

  namespaces_user_namespace :shared_sample_actions_doe_namespace do
    name 'shared.sample.actions.doe@localhost'
    path 'shared.sample.actions.doe_at_localhost'
    owner :shared_sample_actions_doe
    puid 'INXT_USR_AAAAAAAAAV'
  end

  namespaces_user_namespace :subgroup_sample_actions_doe_namespace do
    name 'subgroup.sample.actions.doe@localhost'
    path 'subgroup.sample.actions.doe_at_localhost'
    owner :subgroup_sample_actions_doe
    puid 'INXT_USR_AAAAAAAAAW'
  end

  namespaces_user_namespace :steve_doe_namespace do
    name 'steve.doe@localhost'
    path 'steve.doe_at_localhost'
    owner :steve_doe
    puid 'INXT_USR_AAAAAAAAAX'
  end

  namespaces_user_namespace :user31_namespace do
    name 'user.31@localhost'
    path 'user.31_at_localhost'
    owner :user31
    puid 'INXT_USR_AAAAAAAAAY'
  end

  namespaces_user_namespace :chunked_samples_doe_namespace do
    name 'chunked_samples_doe@localhost'
    path 'chunked-samples-doe-at-localhost'
    owner :chunked_samples_doe
    puid 'INXT_USR_AAAAAAAAAZ'
  end
end
