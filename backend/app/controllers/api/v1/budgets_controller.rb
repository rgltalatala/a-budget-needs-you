module Api
  module V1
    class BudgetsController < BaseController
      include Authenticable
      include Paginatable

      before_action :set_budget, only: [:show, :update, :destroy]

      # GET /api/v1/budgets
      def index
        @budgets = current_user.budgets
        render_paginated(@budgets, Api::V1::BudgetSerializer)
      end

      # GET /api/v1/budgets/:id
      def show
        render json: serialize_object(@budget, Api::V1::BudgetSerializer)
      end

      # POST /api/v1/budgets
      def create
        @budget = current_user.budgets.build(budget_params)

        if @budget.save
          render json: serialize_object(@budget, Api::V1::BudgetSerializer), status: :created
        else
          render json: {
            error: "Validation failed",
            message: @budget.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/budgets/:id
      def update
        if @budget.update(budget_params)
          render json: serialize_object(@budget, Api::V1::BudgetSerializer)
        else
          render json: {
            error: "Validation failed",
            message: @budget.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/budgets/:id
      def destroy
        @budget.destroy
        head :no_content
      end

      private

      def set_budget
        @budget = current_user.budgets.find(params[:id])
      end

      def budget_params
        params.fetch(:budget, {}).permit()
      end
    end
  end
end
