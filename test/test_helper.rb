require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
require 'active_support/testing/declarative'
require 'mocha'

begin
  require 'redgreen' unless ENV['TM_FILENAME']
rescue LoadError
end

class Test::Unit::TestCase
  extend ActiveSupport::Testing::Declarative
end

require 'time_bandits'
