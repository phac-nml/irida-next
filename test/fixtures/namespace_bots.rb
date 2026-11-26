# frozen_string_literal: true

FixtureBot.define do
  21.times do |n|
    namespace_bot(:"project1_bot#{n}") do
      namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project1_namespace)
      user :"user_bot_account#{n}"
    end
  end

  21.times do |n|
    namespace_bot(:"group1_bot#{n}") do
      namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_one)
      user :"user_group_bot_account#{n}"
    end
  end

  namespace_bot :invalid_user_bot do
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/user_namespaces', :john_doe_namespace)
    user :john_doe
  end

  namespace_bot :projectJeff_bot do
    namespace_id FixtureBot::Key::Uuid.generate(:'namespaces/project_namespaces', :project_jeff_namespace)
    user :projectJeff_bot
  end

  namespace_bot :groupJeff_bot do
    namespace_id FixtureBot::Key::Uuid.generate(:groups, :group_jeff)
    user :groupJeff_bot
  end
end
