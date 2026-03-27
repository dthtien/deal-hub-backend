# frozen_string_literal: true

module UniversalStore
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= UniversalStoreCrawler.new
    end
  end
end
