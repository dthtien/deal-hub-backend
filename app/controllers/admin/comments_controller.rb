# frozen_string_literal: true

module Admin
  class CommentsController < Admin::BaseController
    def index
      @comments = Comment.where(status: 'flagged')
                         .order(created_at: :desc)
                         .limit(100)

      render json: @comments.map { |c|
        {
          id: c.id,
          body: c.body,
          name: c.name,
          status: c.status,
          product_id: c.product_id,
          session_id: c.session_id,
          created_at: c.created_at
        }
      }
    end

    def approve
      comment = Comment.find(params[:id])
      comment.update!(status: 'approved')
      render json: { ok: true, status: 'approved' }
    end

    def reject
      comment = Comment.find(params[:id])
      comment.destroy!
      render json: { ok: true }
    end
  end
end
