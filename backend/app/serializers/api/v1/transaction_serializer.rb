module Api
  module V1
    class TransactionSerializer < BaseSerializer
      def serialize_item(item)
        return nil if item.nil?
        
        result = {
          id: item.id.to_s,
          account_id: item.account_id.to_s,
          category_id: item.category_id.to_s,
          date: item.date&.iso8601,
          payee: item.payee,
          amount: item.amount.to_f,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }

        if include?(:account) && item.account
          result[:account] = AccountSerializer.serialize(item.account, options)
        end

        if include?(:category) && item.category
          result[:category] = CategorySerializer.serialize(item.category, options)
        end

        result
      end
    end
  end
end
