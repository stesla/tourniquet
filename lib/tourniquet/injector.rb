class Class
  def inject(deps = {})
    Injector.bind(self, deps)
  end

end

module Tourniquet
  class Injector
    class Binding
      def initialize(klass, deps)
        @klass = klass
        @deps = deps
      end

      def create(injector)
        result = @klass.new
        @deps.each do |name, binding|
          result.instance_variable_set("@#{name}", injector[binding])
        end
        result.after_initialize if result.respond_to? :after_initialize
        result
      end
    end

    class NotFound < Exception; end

    class << self
      def method_missing(name, *args)
        instance.send name, *args
      end

      def instance
        @instance ||= self.new
      end

      def reset_instance
        @instance = nil
      end
    end

    def [] (of)
      get_instance(of)
    end
    
    def bind(klass, args)
      bindings[klass] = Binding.new(klass, args)
    end

    def bindings
      @bindings ||= {}
    end
    
    def has_binding?(klass)
      bindings.has_key? klass
    end
    
    def get_instance(of)
      raise NotFound unless self.class.has_binding? of
      self.class.bindings[of].create(self)
    end
  end
end
