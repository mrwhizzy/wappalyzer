#!/usr/bin/env ruby
# frozen_string_literal: true

require 'wappalyzer/version'

require 'net/http'
require 'mini_racer'
require 'json'
require 'zlib'

Encoding.default_external = Encoding::UTF_8

module Wappalyzer
  # Detector class
  class Detector
    def initialize
      @realdir = __dir__
      file = File.join(@realdir, 'apps.json')
      @json = JSON.parse(IO.read(file))
      @categories = @json['categories']
      @apps = @json['apps']
    end

    def analyze(url)
      uri = URI(url)
      body = nil
      headers = {}
      Net::HTTP.start(uri.host, uri.port,
                      use_ssl: uri.scheme == 'https',
                      verify_mode: OpenSSL::SSL::VERIFY_NONE,
                      open_timeout: 5) do |http|
        begin
          resp = http.get(uri.request_uri)
        rescue Zlib::DataError
          resp = http.get(uri.request_uri, 'Accept-Encoding' => 'none')
        end

        resp.each_header { |k, v| headers[utf8_encoding(k).downcase] = utf8_encoding(v) }
        body = utf8_encoding(resp.body)
      end

      cxt = MiniRacer::Context.new
      cxt.load File.join(@realdir, 'js', 'wappalyzer.js')
      cxt.load File.join(@realdir, 'js', 'driver.js')
      data = { 'host' => uri.hostname, 'url' => url, 'html' => body, 'headers' => headers }
      output = cxt.eval("w.apps = #{@apps.to_json}; w.categories = #{@categories.to_json}; w.driver.data = #{data.to_json}; w.driver.init();")
      JSON.parse(output)
    end

    private

    def utf8_encoding(str)
      str.encode('UTF-8', invalid: :replace, undef: :replace)
    end
  end
end

if $PROGRAM_NAME == __FILE__
  url = ARGV[0]
  if url
    puts JSON.pretty_generate(Wappalyzer::Detector.new.analyze(ARGV[0]))
  else
    puts "Usage: #{__FILE__} http://example.com"
  end
end
