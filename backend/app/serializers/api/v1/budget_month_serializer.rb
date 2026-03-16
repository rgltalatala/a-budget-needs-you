module Api
  module V1
    class BudgetMonthSerializer < BaseSerializer
      def serialize_item(item)
        return nil if item.nil?
        
        result = {
          id: item.id.to_s,
          budget_id: item.budget_id.to_s,
          month: item.month&.iso8601,
          available: item.available.to_f,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }

        if include?(:budget) && item.budget
          result[:budget] = BudgetSerializer.serialize(item.budget, options)
        end

        if include?(:summary) && item.summaries.any?
          result[:summary] = SummarySerializer.serialize(item.summaries.first, options)
        end

        result
      end
    end
  end
end
