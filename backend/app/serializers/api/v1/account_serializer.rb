module Api
  module V1
    class AccountSerializer < BaseSerializer
      def serialize_item(item)
        return nil if item.nil?
        
        result = {
          id: item.id.to_s,
          name: item.name,
          account_type: item.account_type,
          balance: item.balance.to_f,
          account_group_id: item.account_group_id&.to_s,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }

        if include?(:account_group) && item.account_group
          result[:account_group] = AccountGroupSerializer.serialize(item.account_group, options)
        end

        result
      end
    end
  end
end
