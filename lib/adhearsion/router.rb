# encoding: utf-8

%w(
  evented_route
  openended_route
  route
  unaccepting_route
).each { |r| require "adhearsion/router/#{r}" }

module Adhearsion
  class Router
    NoMatchError = Class.new Adhearsion::Error

    attr_reader :routes

    def initialize(&block)
      @routes = []
      instance_exec(&block)
    end

    def route(*args, &block)
      Route.new(*args, &block).tap do |route|
        @routes << route
      end
    end

    def match(call)
      @routes.find { |route| route.match? call }
    end

    def handle(call)
      puts "Router Handle"
      require 'pry'; binding.pry
      raise NoMatchError unless route = match(call)
      logger.info "Call #{call.id} selected route \"#{route.name}\" (#{route.target})"
      route.dispatch call
    rescue NoMatchError
      logger.warn "Call #{call.id} could not find a matching route. Rejecting."
      call.reject :error
    end

    module Filters
      def evented(&block)
        filtered_routes EventedRoute, &block
      end

      def unaccepting(&block)
        filtered_routes UnacceptingRoute, &block
      end

      def openended(&block)
        filtered_routes OpenendedRoute, &block
      end

      def filtered_routes(mixin, &block)
        FilteredRouter.new(self, mixin).instance_exec(&block)
      end
    end

    include Filters

    class FilteredRouter < SimpleDelegator
      include Filters

      def initialize(delegate, mixin)
        super delegate
        @mixin = mixin
      end

      def route(*args, &block)
        super.tap { |r| r.extend @mixin }
      end
    end
  end
end
