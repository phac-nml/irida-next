# frozen_string_literal: true

module SystemFeatureFlags
  # Small return contract for UI-independent feature flag mutation services.
  Result = Data.define(:status, :change, :entry, :error) do
    def success?
      status == :success
    end

    def no_op?
      status == :no_op
    end

    def failure?
      status == :failure
    end
  end
end
