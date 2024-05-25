module JdSports
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= JdSportsCrawler.new
    end
  end
end
