# this file monkey patches class ActiveRecord::LogSubscriber
# to count the number of sql statements being executed
# and the number of query cache hits
# it needs to be adapted to each new rails version

raise "time_bandits ActiveRecord monkey patch is not compatible with your rails version" unless
  Rails::VERSION::STRING =~ /^(3\.[012]|4\.[012])|5.0|5.1/

require "active_record/log_subscriber"

module ActiveRecord
  class LogSubscriber
    IGNORE_PAYLOAD_NAMES = ["SCHEMA", "EXPLAIN"] unless defined?(IGNORE_PAYLOAD_NAMES)

    def self.call_count=(value)
      Thread.current.thread_variable_set(:active_record_sql_call_count, value)
    end

    def self.call_count
      Thread.current.thread_variable_get(:active_record_sql_call_count) ||
        Thread.current.thread_variable_set(:active_record_sql_call_count, 0)
    end

    def self.query_cache_hits=(value)
      Thread.current.thread_variable_set(:active_record_sql_query_cache_hits, value)
    end

    def self.query_cache_hits
      Thread.current.thread_variable_get(:active_record_sql_query_cache_hits) ||
        Thread.current.thread_variable_set(:active_record_sql_query_cache_hits, 0)
    end

    def self.reset_call_count
      calls = call_count
      self.call_count = 0
      calls
    end

    def self.reset_query_cache_hits
      hits = query_cache_hits
      self.query_cache_hits = 0
      hits
    end

    # Rails 4.1 uses method_added to automatically subscribe newly
    # added methods. Since :render_bind and :sql are already defined,
    # the net effect is that sql gets called twice. Therefore, we
    # temporarily switch to protected mode and change it back later to
    # public.

    # Note that render_bind was added for Rails 4.0, and the implementation
    # has changed since then, so we are careful to only redefine it if necessary.
    unless instance_methods.include?(:render_bind)
      protected
      def render_bind(column, value)
        if column
          if column.type == :binary
            value = "<#{value.bytesize} bytes of binary data>"
          end
          [column.name, value]
        else
          [nil, value]
        end
      end
      public :render_bind
      public
    end

    protected
    def sql(event)
      self.class.runtime += event.duration
      self.class.call_count += 1
      self.class.query_cache_hits += 1 if event.payload[:name] == "CACHE"

      return unless logger.debug?

      payload = event.payload

      return if IGNORE_PAYLOAD_NAMES.include?(payload[:name])

      log_sql_statement(payload, event)
    end
    public :sql
    public

    private
    if Rails::VERSION::STRING >= "5.0"
      def log_sql_statement(payload, event)
        name = '%s (%.1fms)' % [payload[:name], event.duration]
        sql  = payload[:sql].squeeze(' ')
        binds = nil

        unless (payload[:binds] || []).empty?
          binds = "  " + payload[:binds].map { |attr| render_bind(attr) }.inspect
        end

        name = colorize_payload_name(name, payload[:name])
        sql  = color(sql, sql_color(sql), true)

        debug "  #{name}  #{sql}#{binds}"
      end
    else
      def log_sql_statement(payload, event)
        name  = "#{payload[:name]} (#{event.duration.round(1)}ms)"
        sql   = payload[:sql]
        binds = nil

        unless (payload[:binds] || []).empty?
          binds = "  " + payload[:binds].map { |col,v| render_bind(col, v) }.inspect
        end

        if odd?
          name = color(name, CYAN, true)
          sql  = color(sql, nil, true)
        else
          name = color(name, MAGENTA, true)
        end

        debug "  #{name}  #{sql}#{binds}"
      end
    end
  end

  require "active_record/railties/controller_runtime"

  module Railties
    module ControllerRuntime
      def cleanup_view_runtime
        # this method has been redefined to do nothing for activerecord on purpose
        super
      end

      def append_info_to_payload(payload)
        super
        if ActiveRecord::Base.connected?
          payload[:db_runtime] = TimeBandits::TimeConsumers::Database.instance.consumed
        end
      end

      module ClassMethods
        # this method has been redefined to do nothing for activerecord on purpose
        def log_process_action(payload)
          super
        end
      end
    end
  end
end
