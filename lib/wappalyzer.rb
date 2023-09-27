#!/usr/bin/env ruby
# frozen_string_literal: true

require 'addressable'
require 'json'
require 'mini_racer'
require 'net/http'
require 'zlib'

Encoding.default_external = Encoding::UTF_8

module Wappalyzer
  # Detector class
  class Detector
    class TooManyRedirectsError < StandardError; end

    IF_MODIFIED_TIME = Time.now - 60 * 60

    REALDIR = __dir__
    JSON_FILE = JSON.parse(IO.read(File.join(REALDIR, 'apps.json')))
    CATEGORIES = JSON_FILE['categories'].to_json
    APPS = JSON_FILE['apps'].to_json

    def analyze(url, redirect_limit = 10, cookies = nil, ref_uri = nil)
      raise TooManyRedirectsError.new('Too many HTTP redirects') if redirect_limit.zero?

      url = url.to_s
      uri = URI(Addressable::URI.escape(url))
      if ref_uri
        uri.scheme = ref_uri.scheme unless uri.scheme
        uri.host = ref_uri.host unless uri.host
        uri.port = ref_uri.port unless uri.port
        uri = URI(uri.to_s)
        url = uri.to_s
      end

      req = build_request(uri, cookies)
      conf = { use_ssl: uri.scheme == 'https', verify_mode: OpenSSL::SSL::VERIFY_NONE, open_timeout: 5 }

      res = Net::HTTP.start(uri.hostname, uri.port, conf) do |http|
        http.request(req)
      rescue Zlib::DataError
        req['Accept-Encoding'] = 'none'
        http.request(req)
      end

      return analyze(res['location'], redirect_limit - 1,
                     res['Set-Cookie'], uri) if res.is_a? Net::HTTPRedirection

      headers = res.each_header.each_with_object({}) { |(k, v), hsh| hsh[utf8_encoding(k).downcase] = utf8_encoding(v) }
      body = utf8_encoding(res.body)

      cxt = MiniRacer::Context.new
      cxt.load(File.join(REALDIR, 'js', 'wappalyzer.js'))
      cxt.load(File.join(REALDIR, 'js', 'driver.js'))
      data = { 'host' => uri.hostname, 'url' => url, 'html' => body, 'headers' => headers }
      output = cxt.eval("w.apps = #{APPS}; w.categories = #{CATEGORIES}; " \
                        "w.driver.data = #{data.to_json}; w.driver.init();")
      JSON.parse(output)
    end

    private

    def utf8_encoding(str)
      str.encode('UTF-8', invalid: :replace, undef: :replace)
    end

    def build_request(uri, cookies = nil)
      req = Net::HTTP::Get.new(uri)

      req['Host'] = uri.host
      req['User-Agent'] = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 11_0_0) AppleWebKit/537.36' \
        '(KHTML, like Gecko) Chrome/86.0.4240.198 Safari/537.36'
      req['Referer'] = 'https://www.google.com/'
      req['Set-Cookie'] = cookies

      req
    end
  end
end

if $PROGRAM_NAME == __FILE__
  if ARGV[0]
    puts JSON.pretty_generate(Wappalyzer::Detector.new.analyze(ARGV[0], ARGV[1].to_i))
  else
    puts "Usage: #{__FILE__} http://example.com [redirects_limit]"
  end
end
