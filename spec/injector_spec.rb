$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tourniquet'

include Tourniquet

describe Tourniquet::Injector do
  it 'should blow up if there is no binding for a class' do
    lambda { Injector.new[:foo] }.should raise_error(NotFound)
  end

  it 'should find a class that has used the inject keyword' do
    klass = Class.new { inject }
    injector = Injector.new do |i|
      i.bind(:klass).to(klass)
    end
    injector[:klass].should be_instance_of(klass)
  end

  it 'should pass in dependencies' do
    dep_foo = Class.new { inject }
    dep_bar = Class.new { inject }

    klass = Class.new do
      inject :foo => :foo, :bar => :bar
      attr_reader :foo, :bar
    end

    injector = Injector.new do |i|
      i.bind(:foo).to(dep_foo)
      i.bind(:bar).to(dep_bar)
      i.bind(:klass).to(klass)
    end

    k = injector[:klass]
    k.should be_instance_of(klass)
    k.foo.should_not be_nil
    k.foo.should be_instance_of(dep_foo)
    k.bar.should_not be_nil
    k.bar.should be_instance_of(dep_bar)
  end

  it 'should call #after_initialize after dependencies are set' do
    klass = Class.new do
      inject
      attr_reader :foo

      def after_initialize
        @foo = []
      end
    end

    injector = Injector.new do |i|
      i.bind(:klass).to(klass)
    end

    k = injector[:klass]
    k.foo.should_not be_nil
    k.foo.should be_empty
  end

  it 'should allow depenencies to be injected manually for testing' do
    klass = Class.new do
      inject :foo => String
      attr_reader :foo
    end

    k = klass.new(:foo => 'bar')
    k.foo.should == 'bar'
  end

  it 'should figure out simple linear dependencies' do
    klass1 = Class.new { inject }
    klass2 = Class.new { inject :one => :klass1; attr_reader :one }
    klass3 = Class.new { inject :two => :klass2; attr_reader :two }

    injector = Injector.new do |i|
      i.bind(:klass1).to(klass1)
      i.bind(:klass2).to(klass2)
      i.bind(:klass3).to(klass3)
    end

    k = injector[:klass3]
    k.two.one.should be_instance_of(klass1)
  end
end
