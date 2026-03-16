module Api
  module V1
    class GoalSerializer < BaseSerializer
      def serialize_item(item)
        return nil if item.nil?
        
        result = {
          id: item.id.to_s,
          category_id: item.category_id.to_s,
          goal_type: item.goal_type,
          target_amount: item.target_amount&.to_f,
          target_date: item.target_date&.iso8601,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }

        # Include progress if requested
        if include?(:progress)
          result[:progress] = GoalTrackingService.calculate_progress(item)
        end

        if include?(:category) && item.category
          result[:category] = CategorySerializer.serialize(item.category, options)
        end

        result
      end
    end
  end
end
