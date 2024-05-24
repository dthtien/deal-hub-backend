module CultureKings
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= CultureKingsCrawler.new
    end
  end
end
