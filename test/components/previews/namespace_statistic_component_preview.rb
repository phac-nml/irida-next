# frozen_string_literal: true

class NamespaceStatisticComponentPreview < ViewComponent::Preview
  # Default Preview
  # ---------------
  # This is the default preview for the NamespaceStatisticComponent.
  # It uses the default (slate) color scheme.
  def default
    render(
      NamespaceStatisticComponent.new(
        id_prefix: 'total-projects',
        icon_name: :user_circle,
        label: I18n.t('components.project_dashboard.information.number_of_automated_workflow_executions'),
        count: 123,
        color_scheme: :default
      )
    )
  end

  # @!group Color Schemes

  # Blue Color Scheme
  # -----------------
  # This preview demonstrates the blue color scheme.
  def blue_scheme
    render(
      NamespaceStatisticComponent.new(
        id_prefix: 'blue-stats',
        icon_name: :user_circle,
        label: I18n.t('components.project_dashboard.information.number_of_automated_workflow_executions'),
        count: 456,
        color_scheme: :blue
      )
    )
  end

  # Teal Color Scheme
  # -----------------
  # This preview demonstrates the teal color scheme.
  def teal_scheme
    render(
      NamespaceStatisticComponent.new(
        id_prefix: 'teal-stats',
        icon_name: :user_circle,
        label: I18n.t('components.project_dashboard.information.number_of_automated_workflow_executions'),
        count: 789,
        color_scheme: :teal
      )
    )
  end

  # Indigo Color Scheme
  # -------------------
  # This preview demonstrates the indigo color scheme.
  def indigo_scheme
    render(
      NamespaceStatisticComponent.new(
        id_prefix: 'indigo-stats',
        icon_name: :user_circle,
        label: I18n.t('components.project_dashboard.information.number_of_members'),
        count: 101,
        color_scheme: :indigo
      )
    )
  end

  # Fuchsia Color Scheme
  # --------------------
  # This preview demonstrates the fuchsia color scheme.
  def fuchsia_scheme
    render(
      NamespaceStatisticComponent.new(
        id_prefix: 'fuchsia-stats',
        icon_name: :user_circle,
        label: I18n.t('components.project_dashboard.information.number_of_automated_workflow_executions'),
        count: 202,
        color_scheme: :fuchsia
      )
    )
  end

  # Amber Color Scheme
  # ------------------
  # This preview demonstrates the amber color scheme.
  def amber_scheme
    render(
      NamespaceStatisticComponent.new(
        id_prefix: 'amber-stats',
        icon_name: :user_circle,
        label: I18n.t('components.project_dashboard.information.number_of_automated_workflow_executions'),
        count: 303,
        color_scheme: :amber
      )
    )
  end

  # @!endgroup
end
