# frozen_string_literal: true

# Migration to update state column in workflow executions from type string to int to utilize enums
class ChangeWorkflowExecutionStateToEnum < ActiveRecord::Migration[7.1]
  def up # rubocop:disable Metrics/MethodLength
    rename_column :workflow_executions, :state, :old_state
    add_column :workflow_executions, :state, :integer

    enum_values = {
      initial: 0,
      prepared: 1,
      submitted: 2,
      running: 3,
      completing: 4,
      completed: 5,
      error: 6,
      canceling: 7,
      canceled: 8,
      queued: 9
    }

    execute <<-SQL.squish
      UPDATE workflow_executions SET state = #{enum_values[:initial]} WHERE old_state = 'new';
      UPDATE workflow_executions SET state = #{enum_values[:prepared]} WHERE old_state = 'prepared';
      UPDATE workflow_executions SET state = #{enum_values[:submitted]} WHERE old_state = 'submitted';
      UPDATE workflow_executions SET state = #{enum_values[:running]} WHERE old_state = 'running';
      UPDATE workflow_executions SET state = #{enum_values[:completing]} WHERE old_state = 'completing';
      UPDATE workflow_executions SET state = #{enum_values[:completed]} WHERE old_state = 'completed';
      UPDATE workflow_executions SET state = #{enum_values[:error]} WHERE old_state = 'error';
      UPDATE workflow_executions SET state = #{enum_values[:canceling]} WHERE old_state = 'canceling';
      UPDATE workflow_executions SET state = #{enum_values[:canceled]} WHERE old_state = 'canceled';
      UPDATE workflow_executions SET state = #{enum_values[:queued]} WHERE old_state = 'queued';
    SQL

    add_index :workflow_executions, :state
    remove_column :workflow_executions, :old_state
  end
end
