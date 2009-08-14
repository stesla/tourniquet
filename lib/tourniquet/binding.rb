# Copyright (c) 2009 Samuel Tesla <samuel.tesla@gmail.com>
#
# Tourniquet is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

module Tourniquet
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

  class ProviderBinding < Binding
    def initialize(injector, interface)
      super(nil, [], false)
      @injector = injector
      @interface = interface
    end

    def instance(_deps)
      Provider.new(@injector, @interface)
    end
  end
end
