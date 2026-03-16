module Api
  module V1
    class BudgetSerializer < BaseSerializer
      def serialize_item(item)
        return nil if item.nil?
        
        {
          id: item.id.to_s,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }
      end
    end
  end
end
