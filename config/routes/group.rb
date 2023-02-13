# frozen_string_literal: true

constraints(Constraints::GroupUrlConstrainer.new) do
  scope(path: '*id',
        as: :group,
        controller: :groups) do
    get '/', action: :show
  end
end
