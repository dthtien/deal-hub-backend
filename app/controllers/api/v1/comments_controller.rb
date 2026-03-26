module Api
  module V1
    class CommentsController < ApplicationController
      def index
        product = Product.find(params[:deal_id])
        comments = product.comments.order(created_at: :asc)
        render json: comments.map { |c|
          { id: c.id, name: c.name, body: c.body, session_id: c.session_id, created_at: c.created_at }
        }
      end

      def create
        product = Product.find(params[:deal_id])
        comment = product.comments.build(comment_params)
        if comment.save
          render json: { id: comment.id, name: comment.name, body: comment.body, session_id: comment.session_id, created_at: comment.created_at }, status: :created
        else
          render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
        end
      end

      private

      def comment_params
        params.require(:comment).permit(:name, :body, :session_id)
      end
    end
  end
end
