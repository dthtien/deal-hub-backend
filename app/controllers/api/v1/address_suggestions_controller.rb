class Api::V1::AddressSuggestionsController < ApplicationController
  def index
    terms = params[:terms]
    if terms.blank?
      return render json: { error: "Missing search terms" }, status: :bad_request
    end

    service = Properties::Suggest.new(terms)

    service.call

    if service.data.present?
      render json: service.data, status: :ok
    else
      render json: { error: "Not Found" }, status: :not_found
    end
  end
end
