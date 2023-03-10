# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

if Rails.env.development?

  # Seed Users
  admin = User.create!({ email: 'admin@cscscience.ca', password: '123456', password_confirmation: '123456' })

  User.create!(
    [
      { email: 'aaron.petkau@cscscience.ca', password: '123456', password_confirmation: '123456' },
      { email: 'eric.enns@cscscience.ca', password: '123456', password_confirmation: '123456' },
      { email: 'jeffrey.thiessen@cscscience.ca', password: '123456', password_confirmation: '123456' },
      { email: 'josh.adam@cscscience.ca', password: '123456', password_confirmation: '123456' },
      { email: 'katherine.thiessen@cscscience.ca', password: '123456', password_confirmation: '123456' },
      { email: 'khiem.bui@cscscience.ca', password: '123456', password_confirmation: '123456' },
      { email: 'sukhdeep.sidhu@cscscience.ca', password: '123456', password_confirmation: '123456' }
    ]
  )

  # Seed Groups
  1.upto(3) do |i|
    parent_group = Group.create!(name: "Group #{i}", path: "group-#{i}",
                                 description: "This is a description for group #{i}.", owner: admin)
    # Seed Subgroups
    1.upto(3) do |j|
      Group.create!(name: "Subgroup #{j}", path: "subgroup-#{j}",
                    description: "This is a description for subgroup #{j}.", owner: admin, parent: parent_group)
    end
  end
end
