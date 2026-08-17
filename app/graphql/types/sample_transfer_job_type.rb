# frozen_string_literal: true

module Types
  # Sample Transfer Job Type
  class SampleTransferJobType < Types::BaseObject
    description 'The status of a sample transfer job.'

    field :errors, [Types::UserErrorType], null: false, description: 'A list of errors that prevented the mutation.'
    field :samples, [ID], null: true, description: 'List of transferred sample ids.'
    field :status, String, null: true, description: 'Status of the transfer job.'
  end
end
