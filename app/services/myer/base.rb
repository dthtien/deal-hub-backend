module Myer
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= MyerCrawler.new
    end
  end
end
