# Copyright (c) 2009 Samuel Tesla <samuel.tesla@gmail.com>
#
# Tourniquet is freely distributable under the terms of an MIT-style license.
# See COPYING or http://www.opensource.org/licenses/mit-license.php.

module Tourniquet
  class Injector
    def initialize(&block)
      @bindings = new_bindings
      block.call(self) unless block.nil?
    end

    def [] (interface)
      get_instance(interface)
    end

    def bind(interface)
      raise AlreadyBound, "#{interface}" if @bindings.has_key? interface
      Verbs::Bind.new do |binding|
        @bindings[interface] = binding
      end
    end

    def get_instance(interface)
      instantiate(interface)
    end

    def instantiate(interface)
      Planner.new(@bindings.dup, interface).create
    end
    private :instantiate

    def new_bindings
      Hash.new do |bindings, interface|
        value = case interface.to_s
                when /^(.*)_provider$/ then Tourniquet::ProviderBinding.new(self, $1.to_sym)
                else nil
                end
        bindings[interface] = value
      end
    end
    private :new_bindings
  end
end
