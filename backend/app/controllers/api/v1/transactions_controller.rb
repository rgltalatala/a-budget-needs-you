module Api
  module V1
    class TransactionsController < BaseController
      include Authenticable
      include Paginatable
      
      before_action :set_transaction, only: [:show, :update, :destroy]

      # GET /api/v1/transactions
      def index
        @transactions = current_user.transactions
        
        # Filter by account_id if provided (must belong to current user)
        if params[:account_id].present?
          account = current_user.accounts.find_by(id: params[:account_id])
          if account
            @transactions = @transactions.where(account_id: account.id)
          else
            # Return empty array if account doesn't belong to user
            @transactions = @transactions.none
          end
        end
        
        # Filter by category_id if provided (must belong to current user)
        if params[:category_id].present?
          category = current_user.categories.find_by(id: params[:category_id])
          if category
            @transactions = @transactions.where(category_id: category.id)
          else
            # Return empty array if category doesn't belong to user
            @transactions = @transactions.none
          end
        end
        
        # Filter by date range if provided (use parsed dates so we compare calendar dates only, not timestamps)
        if params[:start_date].present? && params[:end_date].present?
          start_d = Date.parse(params[:start_date].to_s)
          end_d = Date.parse(params[:end_date].to_s)
          @transactions = @transactions.in_date_range(start_d, end_d)
        elsif params[:start_date].present?
          @transactions = @transactions.from_date(Date.parse(params[:start_date].to_s))
        elsif params[:end_date].present?
          @transactions = @transactions.to_date(Date.parse(params[:end_date].to_s))
        end

        # Filter by payee (case-insensitive substring) if q or payee param provided
        if params[:q].present?
          @transactions = @transactions.search_payee(params[:q].to_s)
        elsif params[:payee].present?
          @transactions = @transactions.search_payee(params[:payee].to_s)
        end

        @transactions = @transactions.recent_first
        
        render_paginated(@transactions, Api::V1::TransactionSerializer)
      end

      # GET /api/v1/transactions/:id
      def show
        render json: serialize_object(@transaction, Api::V1::TransactionSerializer)
      end

      # POST /api/v1/transactions
      def create
        @transaction = current_user.transactions.build(transaction_params)
        
        # Ensure account and category belong to current user
        account = current_user.accounts.find_by(id: transaction_params[:account_id])
        category = current_user.categories.find_by(id: transaction_params[:category_id])
        
        unless account && category
          return render json: {
            error: "Invalid account or category",
            message: "Account and category must belong to the current user"
          }, status: :unprocessable_entity
        end

        if @transaction.save
          render json: serialize_object(@transaction, Api::V1::TransactionSerializer), status: :created
        else
          render json: {
            error: "Validation failed",
            message: @transaction.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/transactions/:id
      def update
        if @transaction.update(transaction_params)
          render json: serialize_object(@transaction, Api::V1::TransactionSerializer)
        else
          render json: {
            error: "Validation failed",
            message: @transaction.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/transactions/:id
      def destroy
        @transaction.destroy
        head :no_content
      end

      private

      def set_transaction
        @transaction = current_user.transactions.find(params[:id])
      end

      def transaction_params
        params.require(:transaction).permit(:account_id, :category_id, :date, :payee, :amount)
      end
    end
  end
end
