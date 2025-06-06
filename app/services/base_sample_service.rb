# frozen_string_literal: true

# Base sample service root class for sample service related classes, scoped by namespace
class BaseSampleService < BaseService
  BaseError = Class.new(StandardError)
  attr_accessor :namespace

  def initialize(namespace, user = nil, params = {})
    super(user, params.except(:namespace, :namespace_id))

    @namespace = namespace
  end

  private

  def authorize_new_project(new_project_id, auth_method)
    # Authorize user against new project authorization method
    @new_project = Project.find_by(id: new_project_id)
    authorize! @new_project, to: auth_method
  end

  def validate(sample_ids, action_type, new_project_id = nil) # rubocop:disable Metrics/CyclomaticComplexity
    puts 'hi'
    if !new_project_id.nil? && new_project_id.blank?
      raise BaseError, I18n.t("services.samples.#{action_type}.empty_new_project_id")
    end

    puts 'hello'
    raise BaseError, I18n.t("services.samples.#{action_type}.empty_sample_ids") if sample_ids.blank?

    puts 'hoho'
    return unless !new_project_id.nil? && new_project_id.present? && @namespace.project_namespace?

    return unless @namespace.project.id == new_project_id

    raise BaseError,
          I18n.t("services.samples.#{action_type}.same_project")
  end

  # Filter the samples that the user has permissions to modify/copy
  def filter_sample_ids(sample_ids, action_type, access_level = Member::AccessLevel::MAINTAINER) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    samples = authorized_scope(Sample, type: :relation, as: :namespace_samples,
                                       scope_options: { namespace: @namespace,
                                                        minimum_access_level: access_level })
              .where(id: sample_ids)
    unauthorized_sample_ids = []
    invalid_ids = []
    not_found_sample_ids = sample_ids - samples.pluck(:id)

    not_found_sample_ids.each do |sample_id|
      sample = Sample.find_by(id: sample_id)
      if sample.nil?
        invalid_ids << sample_id
      else
        unauthorized_sample_ids << sample_id
      end
    end
    # We can combine the invalid_ids and unauthorized_sample_ids at the project level
    # since you can only do actions such as transfer, clone, destroy for samples
    # that are on the project, otherwise we can just return a samples not found message
    invalid_ids += unauthorized_sample_ids if @namespace.project_namespace?

    # We only need to show an unauthorized messages for sample ids that belong to projects in the
    # group since a user can have different access levels
    if unauthorized_sample_ids.count.positive? && @namespace.group_namespace?
      @namespace.errors.add(:samples,
                            I18n.t("services.samples.#{action_type}.unauthorized",
                                   sample_ids: unauthorized_sample_ids.join(', ')))
    end
    if invalid_ids.count.positive?
      @namespace.errors.add(:samples,
                            I18n.t("services.samples.#{action_type}.samples_not_found",
                                   sample_ids: invalid_ids.join(', ')))
    end
    samples
  end
end
