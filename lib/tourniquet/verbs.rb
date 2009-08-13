# Copyright (c) 2009 Samuel Tesla <samuel.tesla@gmail.com>
#
# Tourniquet is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

module Tourniquet
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
end
