module OfficeWorks
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= OfficeWorksCrawler.new
    end
  end
end
