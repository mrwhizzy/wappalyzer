# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'wappalyzer/version'

Gem::Specification.new do |spec|
  spec.name                    = 'wappalyzer'
  spec.version                 = Wappalyzer::VERSION
  spec.required_ruby_version   = '>= 2.5.5'
  spec.authors                 = %w[pulkit21 mrwhizzy]
  spec.email                   = ['pulkit.ag02@gmail.com', 'chr.melas@gmail.com']
  spec.homepage                = 'https://github.com/pulkit21/wappalyzer'
  spec.summary                 = 'Analyzes a provided url and returns any services it can detect'
  spec.description             = 'This analyzes a url and tries to guess what software it uses ' \
                                 '(like server software, CMS, framework, programming language).'

  spec.files                   = Dir['{lib,spec}/**/*', 'README*', 'LICENSE*', 'Rakefile'] &
                                 `if [ -d '.git' ]; then git ls-files -z; fi`.split("\x0")

  spec.add_dependency "addressable", "2.8.1"
  spec.add_dependency "mini_racer", "0.6.3"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"
end
