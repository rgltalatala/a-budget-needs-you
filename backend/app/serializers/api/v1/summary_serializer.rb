module Api
  module V1
    class SummarySerializer < BaseSerializer
      def serialize_item(item)
        return nil if item.nil?
        
        {
          id: item.id.to_s,
          budget_month_id: item.budget_month_id.to_s,
          income: item.income.to_f,
          carryover: item.carryover.to_f,
          available: item.available.to_f,
          notes: item.notes,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }
      end
    end
  end
end
