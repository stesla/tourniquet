class Class
  def inject(deps = {})
    deps.each do |k,v|
      raise Tourniquet::MustBeSymbol, "Dependency key: #{k.inspect}" unless k.instance_of? Symbol
      raise Tourniquet::MustBeSymbol, "Dependency value: #{v.inspect}" unless v.instance_of? Symbol
    end

    @__tourniquet__deps = deps

    class_eval %Q{
      def self.__tourniquet__(&block)
        block.call(self, @__tourniquet__deps)
      end

      def initialize(deps = {})
        #{deps.keys.collect {|k| "@#{k} = deps[:#{k}]"}.join(";")}
        after_initialize
      end

      def after_initialize; end
    }
  end
end
