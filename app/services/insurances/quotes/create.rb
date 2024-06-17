# frozen_string_literal: true

module Insurances
  module Quotes
    class Create < ApplicationService
      attr_reader :quote, :user, :errors

      def initialize(params)
        @params = params
        @errors = []
      end

      def call
        ActiveRecord::Base.transaction do
          create_user
          create_quote
        end

        workflow = Insurances::QuoteWorkflow.create(quote.id)
        workflow.start!
        self
      rescue ActiveRecord::RecordInvalid => e
        @errors << e.message
        self
      end

      def success?
        @errors.empty?
      end

      private

      attr_reader :params

      def create_user
        @user = User.find_or_initialize_by(email: user_params[:email])
        attributes = user_params.slice(
          :first_name, :last_name, :date_of_birth, :phone_number, :gender
        )
        @user.assign_attributes(attributes)

        @user.save!
      end

      def create_quote
        @quote = Quote.new(quote_params)
        @quote.user = @user
        @quote.status = Quote::INITIATED

        @quote.save!
      end

      def quote_params
        params.except(:driver).merge(
          driver_dob: user_params[:date_of_birth],
          driver_first_name: user_params[:first_name],
          driver_last_name: user_params[:last_name],
          driver_gender: user_params[:gender],
          driver_phone_number: user_params[:phone_number],
          driver_email: user_params[:email],
          driver_employment_status: user_params[:employment_status],
          driver_licence_age: user_params[:licence_age]
        )
      end

      def user_params
        params[:driver]
      end
    end
  end
end
