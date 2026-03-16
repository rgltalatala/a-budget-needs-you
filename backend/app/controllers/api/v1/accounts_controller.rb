module Api
  module V1
    class AccountsController < BaseController
      include Authenticable
      include Paginatable
      
      before_action :set_account, only: [:show, :update, :destroy]

      # GET /api/v1/accounts
      def index
        @accounts = current_user.accounts
        render_paginated(@accounts, Api::V1::AccountSerializer)
      end

      # GET /api/v1/accounts/:id
      def show
        render json: serialize_object(@account, Api::V1::AccountSerializer)
      end

      # POST /api/v1/accounts
      def create
        @account = current_user.accounts.build(account_params)

        if @account.save
          render json: serialize_object(@account, Api::V1::AccountSerializer), status: :created
        else
          render json: {
            error: "Validation failed",
            message: @account.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/accounts/:id
      def update
        account_key = params[:account]
        raw_id = account_key&.[](:account_group_id) || account_key&.[]("account_group_id") || account_key&.[](:accountGroupId) || account_key&.[]("accountGroupId")
        if @account.update(account_params)
          # Resolve account_group_id via user's account_groups so we assign the DB id (correct type); then persist so it is not overwritten by account_params
          if raw_id.present?
            group = current_user.account_groups.find_by(id: raw_id)
            # Fallback: resolve by sort_order when id lookup fails (e.g. frontend sent numeric value)
            if group.nil? && raw_id.to_s.match?(/\A\d+\z/)
              group = current_user.account_groups.find_by(sort_order: raw_id.to_i)
            end
            @account.update_columns(account_group_id: group&.id&.to_s)
          elsif raw_id != nil
            @account.update_columns(account_group_id: nil)
          end
          render json: serialize_object(@account, Api::V1::AccountSerializer)
        else
          render json: {
            error: "Validation failed",
            message: @account.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/accounts/:id
      def destroy
        @account.destroy
        head :no_content
      end

      private

      def set_account
        @account = current_user.accounts.find(params[:id])
      end

      def account_params
        params.require(:account).permit(:name, :account_type, :balance, :account_group_id)
      end
    end
  end
end
