# frozen_string_literal: true

FixtureBot.define do
  21.times do |n|
    namespace_bot(:"project1_bot#{n}") do
      namespace_id ActiveRecord::FixtureSet.identify(:project1_namespace, :uuid)
      user_id ActiveRecord::FixtureSet.identify(:"user_bot_account#{n}", :uuid)
    end
  end

  21.times do |n|
    namespace_bot(:"group1_bot#{n}") do
      namespace_id ActiveRecord::FixtureSet.identify(:group_one, :uuid)
      user_id ActiveRecord::FixtureSet.identify(:"user_group_bot_account#{n}", :uuid)
    end
  end

  namespace_bot :invalid_user_bot do
    namespace_id ActiveRecord::FixtureSet.identify(:john_doe_namespace, :uuid)
    user_id ActiveRecord::FixtureSet.identify(:john_doe, :uuid)
  end

  namespace_bot :projectJeff_bot do
    namespace_id ActiveRecord::FixtureSet.identify(:project_jeff_namespace, :uuid)
    user_id ActiveRecord::FixtureSet.identify(:projectJeff_bot, :uuid)
  end

  namespace_bot :groupJeff_bot do
    namespace_id ActiveRecord::FixtureSet.identify(:group_jeff, :uuid)
    user_id ActiveRecord::FixtureSet.identify(:groupJeff_bot, :uuid)
  end
end
