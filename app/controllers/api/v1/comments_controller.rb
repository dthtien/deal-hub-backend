module Api
  module V1
    class CommentsController < ApplicationController
      def index
        product = Product.find(params[:deal_id])
        comments = product.comments.order(created_at: :asc)
        render json: comments.map { |c|
          { id: c.id, name: c.name, body: c.body, status: c.status, session_id: c.session_id, created_at: c.created_at }
        }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def create
        if comment_params[:session_id].blank?
          render json: { errors: ['Session ID is required'] }, status: :unprocessable_entity
          return
        end
        product = Product.find(params[:deal_id])
        comment = product.comments.build(comment_params)
        if comment.save
          render json: {
            id: comment.id,
            name: comment.name,
            body: comment.body,
            status: comment.status,
            session_id: comment.session_id,
            created_at: comment.created_at
          }, status: :created
        else
          render json: { errors: comment.errors.full_messages }, status: :unprocessable_entity
        end
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      def report
        comment = Comment.find(params[:id])
        comment.update!(status: 'flagged')
        render json: { ok: true }
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Not found' }, status: :not_found
      end

      private

      def comment_params
        p = params.require(:comment).permit(:name, :body, :session_id)
        p[:body]       = p[:body].to_s.strip.first(1000) if p[:body]
        p[:name]       = p[:name].to_s.strip.first(100)  if p[:name]
        p[:session_id] = p[:session_id].to_s.first(100)  if p[:session_id]
        p
      end
    end
  end
end
