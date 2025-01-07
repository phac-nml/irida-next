# frozen_string_literal: true

# Validator for advanced search group validator
class AdvancedSearchGroupValidator < ActiveModel::Validator
  def validate(record)
    groups_valid = true
    record.groups.each_with_index do |group, group_index|
      unique_fields = group.conditions.map(&:field).uniq
      unique_fields.each do |unique_field|
        unique_field_conditions = group.conditions.find_all { |condition| condition.field == unique_field }
        unique_field_condition = unique_field_conditions.first

        case unique_field_condition.operator
        when 'contains'
          unless unique_field_conditions.count == 1
            record.groups[group_index].errors.add :base, "'#{unique_field}' can use 'contains' only once."
          end
        when '='
          unless unique_field_conditions.all? { |condition| condition.operator == '=' }
            record.groups[group_index].errors.add :base, "'#{unique_field}' cannot use '=' with other operators."
          end
        when '!='
          unless unique_field_conditions.all? { |condition| condition.operator == '!=' }
            record.groups[group_index].errors.add :base, "'#{unique_field}' cannot use '!=' with other operators."
          end
        when '<='
          unless unique_field_conditions.count == 1 ||
                 (unique_field_conditions.count == 2 && unique_field_conditions[1].operator == '>=')
            record.groups[group_index].errors.add :base, "'#{unique_field}' can use '<=' and '>=' only once."
          end
        when '>='
          unless unique_field_conditions.count == 1 ||
                 (unique_field_conditions.count == 2 && unique_field_conditions[1].operator == '<=')
            record.groups[group_index].errors.add :base, "'#{unique_field}' can use '<=' and '>=' only once."
          end
        end
      end
      groups_valid = false if record.groups[group_index].errors.any?
    end
    return if groups_valid

    record.errors.add :base, 'There are group errors.'
  end
end
