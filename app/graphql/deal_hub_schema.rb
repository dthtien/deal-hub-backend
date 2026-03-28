# frozen_string_literal: true

class DealHubSchema < GraphQL::Schema
  query    Types::QueryType
  mutation Types::MutationType

  # Limit query depth and complexity to prevent abuse
  max_depth 10
  max_complexity 100
end
