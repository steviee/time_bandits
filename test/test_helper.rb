require 'minitest'
require 'mocha/setup'
require 'minitest/pride'
require 'minitest/autorun'

require 'active_support/testing/declarative'
module Test
  module Unit
    class TestCase < Minitest::Test
      extend ActiveSupport::Testing::Declarative
      def assert_nothing_raised(*)
        yield
      end
    end
  end
end

require_relative '../lib/time_bandits'
require "byebug"

ActiveSupport::LogSubscriber.class_eval do
  # need a logger, otherwise no data will be collected
  def logger
    @logger ||= ::Logger.new("/dev/null")
  end
end

# fake Rails
module Rails
  extend self
  module VERSION
    STRING = ActiveSupport::VERSION::STRING
  end
  def cache
    @cache ||= ActiveSupport::Cache.lookup_store(:mem_cache_store)
  end
end
