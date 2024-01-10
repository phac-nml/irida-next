# frozen_string_literal: true

module Types
  # Mutation Type
  class MutationType < Types::BaseObject
    description 'The mutation root of this schema'

    # TODO: remove me
    field :test_field, String, null: false,
                               description: 'An example field added by the generator'
    def test_field
      authorize!(to: :mutate?, with: GraphqlPolicy, context: { user: context[:current_user], token: context[:token] })
      'Hello World'
    end
  end
end
