# frozen_string_literal: true

module LornaJane
  class Base < ApplicationService
    private

    def crawler
      @crawler ||= LornaJaneCrawler.new
    end
  end
end
