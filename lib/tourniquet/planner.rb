# Copyright (c) 2009 Samuel Tesla <samuel.tesla@gmail.com>
#
# Tourniquet is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

module Tourniquet
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

  class Planner
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
end
