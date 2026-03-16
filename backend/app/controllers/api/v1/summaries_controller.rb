module Api
  module V1
    class SummariesController < BaseController
      include Authenticable
      include Paginatable

      before_action :set_summary, only: [:show, :update, :destroy]

      # GET /api/v1/summaries
      def index
        @summaries = current_user.summaries

        # Filter by budget_month_id if provided
        if params[:budget_month_id].present?
          budget_month = current_user.budget_months.find_by(id: params[:budget_month_id])
          @summaries = @summaries.where(budget_month_id: budget_month.id) if budget_month
        end

        render_paginated(@summaries, Api::V1::SummarySerializer)
      end

      # GET /api/v1/summaries/:id
      def show
        render json: serialize_object(@summary, Api::V1::SummarySerializer)
      end

      # POST /api/v1/summaries
      def create
        @summary = current_user.summaries.build(summary_params)

        # Ensure budget_month belongs to current user
        budget_month = current_user.budget_months.find_by(id: summary_params[:budget_month_id])
        unless budget_month
          return render json: {
            error: "Invalid budget month",
            message: "Budget month must belong to the current user"
          }, status: :unprocessable_entity
        end

        if @summary.save
          render json: serialize_object(@summary, Api::V1::SummarySerializer), status: :created
        else
          render json: {
            error: "Validation failed",
            message: @summary.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/summaries/:id
      def update
        if @summary.update(summary_params)
          render json: serialize_object(@summary, Api::V1::SummarySerializer)
        else
          render json: {
            error: "Validation failed",
            message: @summary.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/summaries/:id
      def destroy
        @summary.destroy
        head :no_content
      end

      private

      def set_summary
        @summary = current_user.summaries.find(params[:id])
      end

      def summary_params
        params.require(:summary).permit(:budget_month_id, :income, :carryover, :available, :notes)
      end
    end
  end
end
