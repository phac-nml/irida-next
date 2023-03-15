# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

if Rails.env.development?

  # Users
  admin = User.create!({ email: 'admin@email.com', password: '123456', password_confirmation: '123456' })

  1.upto(3) do |i|
    User.create!({ email: "user#{i}@email.com", password: '123456', password_confirmation: '123456' })
  end

  user1 = User.where(email: 'user1@email.com').first

  # Groups
  1.upto(3) do |i|
    parent_group = Group.create!(name: "Group #{i}", path: "group-#{i}",
                                 description: "This is a description for group #{i}.", owner: admin)
    # Subgroups
    1.upto(3) do |j|
      Group.create!(name: "Subgroup #{j}", path: "subgroup-#{j}",
                    description: "This is a description for subgroup #{j}.", owner: admin, parent: parent_group)
    end
  end

  group1 = Group.where(path: 'group-1').first

  # Group Members
  Members::GroupMember.create!({ user: user1, namespace: group1, created_by: admin,
                                 access_level: Member::AccessLevel::GUEST })

  # Projects
  project1_namespace = Namespaces::ProjectNamespace.create!({ name: 'Project 1', path: 'project-1', owner: admin,
                                                              description: 'This is a description for project 1',
                                                              parent: group1 })
  Project.create!({ creator: admin, namespace: project1_namespace })

  # Project Members
  Members::ProjectMember.create!({ user: user1, namespace: project1_namespace, created_by: admin,
                                   access_level: Member::AccessLevel::GUEST })
end
