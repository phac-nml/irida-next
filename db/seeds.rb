# frozen_string_literal: true

# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)

if Rails.env.development?

  User.create!(
    [
      { email: 'aaron.petkau@phac-aspc.gc.ca', password: '123456', password_confirmation: '123456' },
      { email: 'eric.enns@phac-aspc.gc.ca', password: '123456', password_confirmation: '123456' },
      { email: 'jeffrey.thiessen@phac-aspc.gc.ca', password: '123456', password_confirmation: '123456' },
      { email: 'josh.adam@phac-aspc.gc.ca', password: '123456', password_confirmation: '123456' },
      { email: 'katherine.thiessen@phac-aspc.gc.ca', password: '123456', password_confirmation: '123456' },
      { email: 'khiem.bui@phac-aspc.gc.ca', password: '123456', password_confirmation: '123456' },
      { email: 'sukhdeep.sidhu@phac-aspc.gc.ca', password: '123456', password_confirmation: '123456' }
    ]
  )

end
