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
      inject :foo => :foo
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

  it 'should requre dep keys to be symbols' do
    [42, "foo", Object.new].each do |key|
      lambda { Class.new { inject key => :foo}}.should raise_error(MustBeSymbol)
    end
    lambda { Class.new { inject :foo => :foo}}.should_not raise_error(MustBeSymbol)
  end

  it 'should require dep values to be symbols' do
    [42, "foo", Object.new, Object].each do |value|
      lambda { Class.new { inject :foo => value}}.should raise_error(MustBeSymbol)
    end
    lambda { Class.new { inject :foo => :foo}}.should_not raise_error(MustBeSymbol)
  end

  it 'should blow up on a circular dependency' do
    klass1 = Class.new { inject :x => :klass3 }
    klass2 = Class.new { inject :x => :klass1 }
    klass3 = Class.new { inject :x => :klass2 }

    injector = Injector.new do |i|
      i.bind(:klass1).to(klass1)
      i.bind(:klass2).to(klass2)
      i.bind(:klass3).to(klass3)
    end

    lambda { k = injector[:klass1] }.should raise_error(CircularDependency)
  end

  it 'should give me a new instance every time by default' do
    klass = Class.new { inject }
    injector = Injector.new {|i| i.bind(:klass).to(klass) }
    injector[:klass].should_not == injector[:klass]
  end

  it 'should give me a cached instance if I tell it to' do
    klass = Class.new { inject }
    injector = Injector.new {|i| i.bind(:klass).cached.to(klass) }
    injector[:klass].should == injector[:klass]
  end

  describe 'with caching enabled and circular dependencies' do
    before (:each) do
      klass1 = Class.new { inject :two => :klass2; attr_reader :two }
      klass2 = Class.new { inject :one => :klass1; attr_reader :one }

      @injector = Injector.new do |i|
        i.bind(:klass1).cached.to(klass1)
        i.bind(:klass2).to(klass2)
      end
    end

    it 'should not blow up' do
      lambda { @injector[:klass1] }.should_not raise_error
    end

    it 'should have circular references' do
      one = @injector[:klass1]
      one.should respond_to(:two)
      one.two.should respond_to(:one)
      one.two.one.should respond_to(:two)
      one.two.one.two.should == one.two
    end
  end

  it 'cannot bind more than one implementation for an interface' do
    klass1 = Class.new { inject }
    klass2 = Class.new { inject }

    injector = Injector.new do |i|
      i.bind(:foo).to(klass1)
    end
    lambda { injector.bind(:foo).to(klass2) }.should raise_error(AlreadyBound)
  end

  it 'can bind a specific instance' do
    injector = Injector.new do |i|
      i.bind(:db_user).to_instance("bob")
    end

    injector[:db_user].should == "bob"
  end

  it 'should bind providers' do
    klass1 = Class.new { inject }
    klass2 = Class.new do
      inject :provider => :klass1.provider
      attr_reader :provider
    end

    injector = Injector.new do |i|
      i.bind(:klass1).to(klass1)
      i.bind(:klass2).to(klass2)
    end

    k = injector[:klass2]
    k.provider.should respond_to(:get_instance)
    k.provider.get_instance.should be_instance_of(klass1)
  end
end
