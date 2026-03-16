module Api
  module V1
    class CategoryGroupSerializer < BaseSerializer
      def serialize_item(item)
        return nil if item.nil?
        
        {
          id: item.id.to_s,
          name: item.name,
          is_default: item.is_default,
          budget_month_id: item.budget_month_id&.to_s,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }
      end
    end
  end
end
