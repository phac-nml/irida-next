# frozen_string_literal: true

# entity class for Member
class GroupMember < Member
  belongs_to :group, foreign_key: :namespace_id, inverse_of: :group
end
