class Class
  def inject(deps = {})
    Injector.bind(self, deps)

    class_eval %Q{
      def initialize(deps = {})
        #{deps.keys.collect {|k| "@#{k} = deps[:#{k}]"}.join(";")}
        after_initialize
      end

      def after_initialize; end
    }
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
        deps = {}
        @deps.each do |name, binding|
          deps[name] = injector[binding]
        end
        @klass.new deps
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
