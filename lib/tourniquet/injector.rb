class Class
  def inject(deps = {})
    deps.each do |k,v|
      raise Tourniquet::MustBeSymbol, "Dependency key: #{k.inspect}" unless k.instance_of? Symbol
      raise Tourniquet::MustBeSymbol, "Dependency value: #{v.inspect}" unless v.instance_of? Symbol
    end

    @__tourniquet__deps = deps

    class_eval %Q{
      def self.__tourniquet__
        Tourniquet::Binding.new(self, @__tourniquet__deps)
      end

      def initialize(deps = {})
        #{deps.keys.collect {|k| "@#{k} = deps[:#{k}]"}.join(";")}
        after_initialize
      end

      def after_initialize; end
    }
  end
end

module Tourniquet
  class MustBeSymbol < Exception; end
  class NotFound < Exception; end

  class Binding
    def initialize(klass, deps)
      @klass = klass
      @deps = deps
    end

    def create(injector)
      deps = {}
      @deps.each do |name, interface|
        deps[name] = injector[interface]
      end
      @klass.new deps
    end
  end

  module Verbs
    class Bind
      def initialize(&block)
        @block = block
      end

      def to(impl)
        binding = impl.__tourniquet__
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
    
    def has_binding?(klass)
      bindings.has_key? klass
    end
    
    def get_instance(interface)
      raise NotFound, "#{interface}" unless has_binding? interface
      bindings[interface].create(self)
    end
  end
end
