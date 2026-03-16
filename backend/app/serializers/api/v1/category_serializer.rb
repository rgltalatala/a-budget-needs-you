module Api
  module V1
    class CategorySerializer < BaseSerializer
      def serialize_item(item)
        return nil if item.nil?
        
        result = {
          id: item.id.to_s,
          user_id: item.user_id&.to_s,
          name: item.name,
          is_default: item.is_default,
          category_group_id: item.category_group_id&.to_s,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }

        if include?(:category_group) && item.category_group
          result[:category_group] = CategoryGroupSerializer.serialize(item.category_group, options)
        end

        if include?(:goal) && item.goal
          result[:goal] = GoalSerializer.serialize(item.goal, options)
        end

        result
      end
    end
  end
end
