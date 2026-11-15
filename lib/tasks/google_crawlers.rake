# frozen_string_literal: true

require 'ipaddr'
require 'json'
require 'net/http'

namespace :crawlers do
  desc 'Refresh config/google_crawler_networks.yml from the address lists Google publishes'
  task :update_google_ranges do
    base = 'https://developers.google.com/static/crawling/ipranges/'
    lists = %w[common-crawlers.json special-crawlers.json user-triggered-fetchers-google.json]

    dates = []
    networks = lists.flat_map do |name|
      body = Net::HTTP.get_response(URI(base + name)).tap(&:value).body
      data = JSON.parse(body)
      dates << data['creationTime'].to_s[0, 10]
      data.fetch('prefixes').map { |p| p['ipv4Prefix'] || p['ipv6Prefix'] }
    end.compact.uniq

    networks.each { |cidr| IPAddr.new(cidr) } # fail before writing if anything is not an address range
    raise 'Google returned no address ranges' if networks.empty?

    path = File.expand_path('../../config/google_crawler_networks.yml', __dir__)
    header = File.readlines(path).take_while { |line| line.start_with?('#') }.join
    File.write(path, <<~YAML)
      #{header.chomp}
      generated_from_lists_dated: "#{dates.max}"
      networks:
      #{networks.map { |cidr| "  - #{cidr}" }.join("\n")}
    YAML
    puts "Wrote #{networks.size} ranges (lists dated #{dates.max}) to #{path}"
  end
end
