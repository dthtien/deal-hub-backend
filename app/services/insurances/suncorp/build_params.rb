# frozen_string_literal: true

module Insurances
  module Suncorp
    class BuildParams
      COVER_TYPES = {
        'comprehensive' => 'Car Comprehensive',
        '3rd_party' => 'Car Third Party Property Damage',
        '3rd_party_fire_theft' => 'Car Third Party Fire and Theft'
      }.freeze

      PARKING_INDICATORS = {
        'same_suburb' => 'Same suburb',
        'another_suburb' => 'Another suburb',
        'multple_suburbs' => 'Multiple suburbs',
      }.freeze
      USAGE_TYPES = {
        'private' => 'Private',
        'business' => 'Business',
        'ridesharing' => 'Ridesharing',
      }.freeze
      BUSINESS_TYPES = {
        'saleperson' => 'On road professional/Salesperson',
        'tradesperson' => 'Tradesperson',
        'car_sharing' => 'Car Sharing',
        'courier' => 'Courier/Delivery driver',
        'driver_education' => 'Driver education',
        'hire' => 'Hire/Courtesy',
        'racing' => 'Racing/Sporting events',
        'removalist' => 'Removalist',
        'taxi' => 'Taxi'
      }.freeze

      DAY_WFH_TYPES = {
        '0' => '0 Days',
        '1_to_2' => '1 - 2 Days',
        '3_to_4' => '3 - 4 Days',
        '5_plus' => '5+ Days',
        'none' => "I don't work or study"
      }

      attr_reader :params

      def initialize(details)
        @details = details
        @params = {}
      end

      def call
        @params[:quoteDetails] = quote_details
        @params[:vehicleDetails] = vehicle_details
        @params[:coverDetails] = cover_details
        @params[:riskAddress] = risk_address
        @params[:driverDetails] = driver_details

        self
      end

      private

      attr_reader :details

      def driver_details
        {
          "mainDriver": {
            "dateOfBirth": details[:driver_dob],
            "gender": details[:driver_gender],
            "hasClaimOccurrences": details[:has_claim_occurrences],
            "claimOccurrences": details[:claim_occurrences],
          },
          "additionalDrivers": details[:additional_drivers]
        }
      end

      def risk_address
        {
          postcode: address_details['postcode'],
          state: address_details['state'],
          suburb: address_details['suburb'],
          lurn: address_details['addressId'],
          lurnScale: address_details['addressQualityLevel'],
          geocodedNationalAddressFileData: address_details['geocodedNationalAddressFileData'],
          pointLevelCoordinates: address_details['pointLevelCoordinates'],
          spatialReferenceId: address_details.dig('geocodedNationalAddressFileData', 'gnafSrid'),
          hopewiserVersion: 'V3 AUS GNAF',
          matchStatus: 'HAPPY',
          structuredStreetAddress: address_details['addressInBrokenDownForm'].except('streetNumber1')
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

      def cover_details
        {
          "coverType": COVER_TYPES[details[:cover_type]],
          "hasWindscreenExcessWaiver": false,
          "hasHireCar": false,
          "hasRoadAssist": false,
          "hasFireAndTheft": false
        }
      end

      def vehicle_details
        {
          "nvic": car_details.dig('vehicleDetails', 'nvic'),
          "highPerformance": nil,
          "financed": details[:financed],
          "usage": {
            "primaryUsage": USAGE_TYPES[details[:primary_usage]],
            "businessType": BUSINESS_TYPES[details[:business_type]],
            "showStampDutyModal": false,
            "backFromJeopardy": false
          },
          "kmPerYear": km_per_year,
          "regoNumber": details[:plate],
          "daysWfh": DAY_WFH_TYPES[details[:days_wfh]],
          "daytimeParking": parking_params,
          "peakHourDriving": details[:peak_hour_driving],
          "vehicleInfo": vehicle_info
        }
      end

      def km_per_year
        number = details[:km_per_year]
        case number
        when 0..5000
          'Up to 5,000 kms a year'
        when 5001..10_000
          'Up to 10,000 kms a year'
        when 10_001..15_000
          'Up to 15,000 kms a year'
        when 15_001..Float::INFINITY
          'More than 15,000 kms a year'
        end
      end

      def parking_params
        {
          "indicator": PARKING_INDICATORS[details.dig(:parking, :indicator)],
          "suburb": details.dig(:parking, :suburb),
          "postcode": details.dig(:parking, :postcode)
        }
      end

      def vehicle_info
        {
          "make": car_details.dig('vehicleDetails', 'make'),
          "family": car_details.dig('vehicleDetails', 'family').upcase
        }
      end

      def quote_details
        market_value = car_details.dig('vehicleValueInfo', 'brandValue')
        {
          quoteNumber: '',
          policyStartDate: details[:policy_start_date],
          acceptDutyOfDisclosure: true,
          currentInsurer: details[:current_insurer],
          sumInsured: {
            marketValue: market_value,
            agreedValue: market_value,
            sumInsuredType: 'Agreed Value'
          },
          campaignCode: ''
        }
      end

      def car_details
        @car_details ||=
          begin
            service = VehicleSearch.new(details[:state], details[:plate], details[:policy_start_date])
            service.call
            service.data
          end
      end
    end
  end
end
