# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

if Rails.env.development?

  num_users = 10
  num_records = 20

  # Users
  admin = User.create!({ email: 'admin@email.com', password: 'password1', password_confirmation: 'password1' })

  1.upto(num_users) do |i|
    User.create!({ email: "user#{i}@email.com", password: 'password1', password_confirmation: 'password1' })
  end

  all_users = User.all

  all_users.each do |user| # rubocop:disable Metrics/BlockLength
    # Groups
    1.upto(rand(num_records)) do |i|
      parent_group = Groups::CreateService.new(user, { name: "Group #{i}", path: "group-#{i}",
                                                       description: "This is a description for group #{i}." }).execute
      # Subgroups
      1.upto(rand(num_records)) do |j|
        Groups::CreateService.new(user, { name: "Subgroup #{j}", path: "subgroup-#{j}",
                                          description: "This is a description for subgroup #{j}.",
                                          parent: parent_group }).execute
      end
    end

    available_users = all_users.to_a - [user]
    groups = Group.where(owner: user)

    groups.each do |group|
      1.upto(rand(num_records)) do |_i|
        available_user = available_users.sample
        Members::CreateService.new(admin, group, { user: available_user,
                                                   access_level: Member::AccessLevel::GUEST }).execute
      end

      1.upto(rand(num_records)) do |i|
        # Projects
        project = Projects::CreateService.new(user, { namespace_attributes: {
                                                name: "Project #{i}", path: "project-#{i}",
                                                description: "This is a description for project #{i}.",
                                                parent: group
                                              } }).execute

        # Project Members
        1.upto(rand(num_records)) do |_i|
          available_user = available_users.sample
          Members::CreateService.new(user, project.namespace, { user: available_user,
                                                                access_level: Member::AccessLevel::GUEST }).execute
        end

        # Samples
        1.upto(rand(num_records)) do |j|
          Samples::CreateService.new(user, project.namespace,
                                     { name: "Sample #{j}}}",
                                       description: "This is a description for sample #{j}." }).execute
        end
      end
    end
  end
end
