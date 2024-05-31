# frozen_string_literal: true

class TheGoodGuysCrawler < ApplicationCrawler
  SALE_IDS_URL = 'https://homepage-white-tiles-default-rtdb.firebaseio.com/data.json'
  SALE_DEALS_URL = 'https://firestore.googleapis.com/v1/projects/tgg-web-api/databases/(default)/documents:runQuery'
  def initialize
    super('')
  end

  def crawl_all
    sale_ids.each do |ids|
      response = fetch_list(build_params(ids))
      @data += JSON.parse(response.body).map { |product| product['document'] }
    end

    self
  end

  private

  def fetch_list(params)
    client.post(SALE_DEALS_URL) do |req|
      req.body = params.to_json
      req.headers['Content-Type'] = 'application/json'
    end
  end

  def sale_ids
    @sale_ids ||= fetch_sale_ids.in_groups_of(29)
  end

  def build_ids_query(ids)
    ids.map { |id| { stringValue: id.to_s } }.uniq
  end

  def fetch_sale_ids
    response = client.get(SALE_IDS_URL)
    response_body = JSON.parse(response.body)

    response_body['whiteTilesData'].compact.map { |a| a['sku'] }
  end

  def build_params(ids)
    {
      structuredQuery: {
        from: [
          {
            collectionId: 'products'
          }
        ],
        where: {
          fieldFilter: {
            field: {
              fieldPath: 'sku'
            },
            op: 'IN',
            value: {
              arrayValue: {
                values: build_ids_query(ids)
              }
            }
          }
        },
        orderBy: [
          {
            field: {
              fieldPath: '__name__'
            },
            direction: 'ASCENDING'
          }
        ]
      }
    }
  end
end
