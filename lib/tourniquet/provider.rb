# Copyright (c) 2009 Samuel Tesla <samuel.tesla@gmail.com>
#
# Tourniquet is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

module Tourniquet
  class Provider
    def initialize(injector, interface)
      @injector = injector
      @interface = interface
    end

    def get_instance
      @injector[@interface]
    end

    def inspect
      "<Tourniquet::Provider #{@interface.inspect}>"
    end
  end
end
