module Tourniquet
  class CircularDependency < Exception; end
  class MustBeSymbol < Exception; end
  class NotFound < Exception; end

  class Binding
    def initialize(klass, deps, caching)
      @klass = klass
      @deps = deps
      @caching = caching
    end

    def each_dep(&block)
      @deps.each(&block)
    end

    def cached?
      caching? && @cache
    end

    def caching?
      @caching
    end

    def instance(deps)
      return @cache if cached?
      @cache = @klass.new deps
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

    def instantiate(interface, ancestors)
      binding = @bindings[interface]
      binding.each_dep do |_name, dep|
        next if @bindings[dep].caching?
        raise CircularDependency, "#{interface} -> #{dep}" if ancestors.include? dep
      end

      deps = {}

      binding.each_dep do |name, dep|
        if @bindings[dep].caching?
          deps[name] = Lazy.new(@bindings[dep])
        else
          deps[name] = instantiate(dep, ancestors + [interface])
        end
      end
      binding.instance(deps)
    end

    def create
      instantiate(@interface, [])
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
    end
  end

  class Injector
    def initialize(&block)
      block.call(self) unless block.nil?
    end

    def [] (interface)
      get_instance(interface)
    end

    def bind(interface)
      Verbs::Bind.new do |binding|
        bindings[interface] = binding
      end
    end

    def bindings
      @bindings ||= {}
    end
    private :bindings

    def get_instance(interface)
      raise NotFound, "#{interface}" unless bindings.has_key? interface
      instantiate(interface)
    end

    def instantiate(interface)
      Planner.new(bindings.dup, interface).create
    end
    private :instantiate
  end
end
