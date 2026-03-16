module Api
  module V1
    class AccountGroupsController < BaseController
      include Authenticable
      include Paginatable
      
      before_action :set_account_group, only: [:show, :update, :destroy]

      # GET /api/v1/account_groups
      def index
        @account_groups = current_user.account_groups
        render_paginated(@account_groups, Api::V1::AccountGroupSerializer)
      end

      # GET /api/v1/account_groups/:id
      def show
        render json: serialize_object(@account_group, Api::V1::AccountGroupSerializer)
      end

      # POST /api/v1/account_groups
      def create
        @account_group = current_user.account_groups.build(account_group_params)

        if @account_group.save
          render json: serialize_object(@account_group, Api::V1::AccountGroupSerializer), status: :created
        else
          render json: {
            error: "Validation failed",
            message: @account_group.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/account_groups/:id
      def update
        if @account_group.update(account_group_params)
          render json: serialize_object(@account_group, Api::V1::AccountGroupSerializer)
        else
          render json: {
            error: "Validation failed",
            message: @account_group.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/account_groups/:id
      def destroy
        # Check if account group has accounts
        if @account_group.accounts.any?
          render json: {
            error: "Cannot delete account group",
            message: "This account group has associated accounts. Please remove or reassign accounts first."
          }, status: :unprocessable_entity
        else
          @account_group.destroy
          head :no_content
        end
      end

      private

      def set_account_group
        @account_group = current_user.account_groups.find(params[:id])
      end

      def account_group_params
        params.require(:account_group).permit(:name, :sort_order)
      end
    end
  end
end
