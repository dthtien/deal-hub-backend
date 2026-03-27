# frozen_string_literal: true

module BeginningBoutique
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= BeginningBoutiqueCrawler.new
    end
  end
end
