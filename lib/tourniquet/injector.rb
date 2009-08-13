# Copyright (c) 2009 Samuel Tesla <samuel.tesla@gmail.com>
#
# Tourniquet is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

module Tourniquet
  class AlreadyBound < Exception; end
  class CircularDependency < Exception; end
  class MustBeSymbol < Exception; end
  class NotFound < Exception; end

  class Binding
    def initialize(klass, deps, caching)
      @klass = klass
      @deps = deps
      @caching = caching
    end

    def cached?
      caching? && @cache
    end

    def caching?
      @caching
    end

    def each_dep(&block)
      @deps.each(&block)
    end

    def instance(deps)
      return @cache if cached?
      @cache = @klass.new deps
    end
  end

  class InstanceBinding < Binding
    def initialize(instance)
      super(nil, [], false)
      @instance = instance
    end

    def instance(_deps)
      @instance
    end
  end

  class Planner
    class Lazy
      def initialize(binding)
        @binding = binding
      end

      def instance
        raise "No cached instance to lazy load" unless @binding.cached?
        @binding.instance(nil)
      end

      def method_missing(message, *args)
        instance.send(message, *args)
      end

      def respond_to?(message)
        instance.respond_to? message
      end
    end

    def initialize(bindings, interface)
      @bindings, @interface = bindings, interface
    end

    def create
      instantiate(@interface, [])
    end

    private

    def caching?(dep)
      @bindings[dep].caching?
    end

    def calculate_dependencies(interface, ancestors, binding)
      result = {}
      binding.each_dep do |name, dep|
        if caching? dep
          result[name] = Lazy.new(@bindings[dep])
        else
          result[name] = instantiate(dep, ancestors + [interface])
        end
      end
      result
    end

    def check_dependencies(interface, ancestors, binding)
      binding.each_dep do |_name, dep|
        next if caching? dep
        raise CircularDependency, "#{interface} -> #{dep}" if ancestors.include? dep
      end
    end

    def instantiate(interface, ancestors)
      binding = @bindings[interface]
      check_dependencies(interface, ancestors, binding)
      deps = calculate_dependencies(interface, ancestors, binding)
      binding.instance(deps)
    end
  end

  module Verbs
    class Bind
      def initialize(&block)
        @block = block
      end

      def cached
        @cached = true
        self
      end

      def to(impl)
        binding = impl.__tourniquet__ do |klass, deps|
          Binding.new(klass, deps, !!@cached)
        end
        @block.call(binding)
      end

      def to_instance(instance)
        @block.call(InstanceBinding.new(instance))
      end
    end
  end

  class Injector
    def initialize(&block)
      @bindings = {}
      block.call(self) unless block.nil?
    end

    def [] (interface)
      get_instance(interface)
    end

    def bind(interface)
      raise AlreadyBound, "#{interface}" if @bindings.has_key? interface
      Verbs::Bind.new do |binding|
        @bindings[interface] = binding
      end
    end

    def get_instance(interface)
      raise NotFound, "#{interface}" unless @bindings.has_key? interface
      instantiate(interface)
    end

    def instantiate(interface)
      Planner.new(@bindings.dup, interface).create
    end
    private :instantiate
  end
end
