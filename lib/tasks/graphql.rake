# frozen_string_literal: true

namespace :graphql do
  task dump_schema: :environment do
    # Get a string containing the definition in GraphQL IDL:
    schema_defn = IridaSchema.to_definition
    # Choose a place to write the schema dump:
    schema_path = 'app/graphql/schema.graphql'
    # Write the schema dump to that file:
    Rails.root.join(schema_path).write(schema_defn)
    puts "Updated #{schema_path}"
  end
end
