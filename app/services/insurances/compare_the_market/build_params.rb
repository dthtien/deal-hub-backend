# frozen_string_literal: true

module Insurances
  module CompareTheMarket
    class BuildParams < ApplicationService
      attr_reader :params

      EMPLOYMENT_STATUSES = {
        'full_time' => 'EMPLOYED_FULL_TIME',
        'part_time' => 'EMPLOYED_PART_TIME',
        'self_employed' => 'SELF_EMPLOYED',
        'retired' => 'RETIRED',
        'student' => 'STUDENT',
        'unemployed' => 'UNEMPLOYED',
        'home_duties' => 'HOUSE_WIFE_OR_HUSBAND'
      }.freeze
      GENDERS = {
        'male' => 'MALE',
        'female' => 'FEAMLE'
      }.freeze
      PARKING_TYPES = {
        'garage' => 'GARAGED',
        'car_park' => 'CAR_PARK',
        'street' => 'STREET',
        'parking_lot' => 'PARKING_LOT',
        'driveway' => 'DRIVEWAY',
      }.freeze
      COVER_TYPES = {
        'comprehensive' => 'COMPREHENSIVE',
        '3rd_party' => 'TPPD',
        '3rd_party_fire_theft' => 'TPFT'
      }.freeze
      FINANCE_TYPES = {
        'none' => 'NONE',
        'leased' => 'LEASED',
        'hire' => 'FINANCE_HIRE_PURCHASE'
      }.freeze
      USE_TYPES = {
        'private' => 'PRIVATE_AND_COMMUTING_TO_WORK',
        'ridesharing' => 'PRIVATE_BUSINESS',
        'business' => 'BUSINESS_ONLY'
      }.freeze
      PREVIOUS_CLAIMS = {
        'no' => 'NO',
        'yes' => 'YES',
        'unsure' => 'UNSURE'
      }.freeze
      RATING_TYPES = {
        '5' => 'RATING_5',
        '6' => 'RATING_6',
      }.freeze
      OTHER_ACCESSORIES = {
        'no' => 'NO',
        'yes' => 'YES',
        'unsure' => 'UNSURE'
      }.freeze
      DRIVER_OPTIONS = {
        'drivers_21' => 'DRIVERS_21_AND_OVER',
        'drivers_25' => 'DRIVERS_25_AND_OVER',
        'none' => 'NO_RESTRICTION'
      }.freeze

      def initialize(details, token_data)
        @details = details
        @token_data = token_data.with_indifferent_access
        @params = {}
      end

      def call
        @params = transaction_data.slice(:transaction, :control)
        @params[:prefill] = {
          lastViewedPage: '/car-insurance/journey/results',
          eligiblePage: true
        }

        @params[:form] = form_params

        self
      end

      private

      attr_reader :details, :token_data

      def transaction_data
        @transaction_data ||= CreateTransaction.new(token_data)
          .call.data.with_indifferent_access
      end

      def cover_detail
        finace_type = details[:financed] ? 'LEASED' : 'NONE'
        {
          useType: USE_TYPES[details[:primary_usage]],
          previousInsurer: details[:current_insurer],
          requestedExcess: '600',
          commencementDate: details[:policy_start_date],
          currentlyInsured: details[:current_insurer].present?,
          annualKilometres: details[:km_per_year],
          requestedExcessHigh: '900',
          requestedExcessLow: '800',
          driver: driver_detail,
          ownsHome: false,
          vehicle: vehicle_detail,
          coverType: COVER_TYPES[details[:cover_type]],
          hasYoungerDriver: details[:has_younger_driver],
          financeType: finace_type,
          overnightParking: overnight_parking,
          driverOption: DRIVER_OPTIONS[details[:driver_option]],
          ownsAnotherCar: false
        }
      end

      def applicant_detail
        {
          firstName: details[:first_name] || details[:driver_first_name],
          lastName: details[:last_name] || details[:driver_last_name],
          optInPrivacy: true
        }
      end

      def overnight_parking
        street_name = address_details.dig('addressInBrokenDownForm', 'streetName')
        street_type = address_details.dig('addressInBrokenDownForm', 'streetType')
        street_number = address_details.dig('addressInBrokenDownForm', 'streetNumber')
        {
          address: address_details.slice('suburb', 'postcode', 'state').merge(
            streetName: "#{street_name} #{street_type}",
            streetNumber: street_number,
            gnafId: address_details.dig('geocodedNationalAddressFileData', 'gnafAddressDetailPID')
          ),
          parkingType: PARKING_TYPES[details.dig(:parking, :type)] || 'CAR_PARK'
        }
      end

      def address_details
        @address_details ||=
          begin
            service = Address::Check.new(details[:suburb], details[:postcode], details[:state], details[:address_line1])
            service.call

            service.data['matchedAddress']
          end
      end

      def vehicle_detail
        other_accessories = details[:has_other_accessories] ? 'yes' : 'no'
        {
          body: car_detail.dig('body', 'code'),
          redbookCodeLong: car_detail['redbookCodeLong'],
          badge: car_detail.dig('badge', 'code') || 'NO_BADGE',
          transmission: car_detail.dig('transmission', 'code') || 'NOT_MANUAL',
          redbookCode: car_detail['redbookCode'],
          modified: details[:modified],
          model: car_detail.dig('model', 'code'),
          glassCode: car_detail['glassCode'],
          colour: car_detail.dig('colour', 'code'),
          nviCode: car_detail['nviCode'],
          make: car_detail.dig('make', 'code'),
          state: details[:state],
          alarmFitted: car_detail['alarmFitted'],
          marketValue: car_detail['marketValue'],
          damaged: details[:damaged],
          fuel: car_detail.dig('fuel', 'code'),
          immobiliserFitted: car_detail['immobiliserFitted'],
          hasOtherAccessories: OTHER_ACCESSORIES[other_accessories],
          rego: details[:plate],
          description: car_detail['vehicleDescription'],
          year: car_detail['year']
        }
      end

      def car_detail
        @car_detail ||= VehicleSearch.new(details[:plate_state], details[:plate], token_data[:access_token])
                                     .call.data
      end

      def driver_detail
        previous_claims = details[:has_claim_occurrences] ? 'yes' : 'no'
        {
          gender: GENDERS[details[:driver_gender]],
          dob: details[:driver_dob],
          employmentStatus: EMPLOYMENT_STATUSES[details[:driver_employment_status] || 'full_time'],
          licenceAge: details[:driver_licence_age],
          anyPreviousClaims: PREVIOUS_CLAIMS[previous_claims],
          noClaimRating: calculate_no_claim_rating,
          firstName: details[:driver_first_name],
          lastName: details[:driver_last_name]
        }
      end

      def calculate_no_claim_rating
        return 'RATING_3' unless details[:has_claim_occurrences]

        RATING_TYPES[details[:claim_occurrences].count.to_s] || 'RATING_6'
      end

      def form_params
        {
          coverDetail: cover_detail,
          applicant: applicant_detail,
          leadCapture: {
            health: false
          },
          helpers: {
            isDisclaimerContentExpanded: false
          }
        }
      end
    end
  end
end
