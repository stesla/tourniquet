# Copyright (c) 2009 Samuel Tesla <samuel.tesla@gmail.com>
#
# Tourniquet is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

class Class
  def inject(deps = {})
    deps.each do |name, interface|
      raise Tourniquet::MustBeSymbol, "Dependency key: #{name.inspect}" unless name.instance_of? Symbol
      raise Tourniquet::MustBeSymbol, "Dependency value: #{interface.inspect}" unless interface.instance_of? Symbol
    end

    @__tourniquet__deps = deps

    class_eval %Q{
      def self.__tourniquet__(&block)
        block.call(self, @__tourniquet__deps)
      end

      def initialize(deps = {})
        #{deps.keys.collect {|name| "@#{name} = deps[:#{name}]"}.join(";")}
        after_initialize
      end

      def after_initialize; end
    }
  end
end
