module Api
  module V1
    class CategoryMonthSerializer < BaseSerializer
      def serialize_item(item)
        return nil if item.nil?
        
        result = {
          id: item.id.to_s,
          category_id: item.category_id.to_s,
          category_group_id: item.category_group_id&.to_s,
          month: item.month&.iso8601,
          allotted: item.allotted.to_f,
          spent: item.spent.to_f,
          balance: item.balance.to_f,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }

        if include?(:category) && item.category
          result[:category] = CategorySerializer.serialize(item.category, options)
        end

        if include?(:category_group) && item.category_group
          result[:category_group] = CategoryGroupSerializer.serialize(item.category_group, options)
        end

        result
      end
    end
  end
end
