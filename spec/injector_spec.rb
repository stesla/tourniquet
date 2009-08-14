$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tourniquet'

include Tourniquet

describe Tourniquet::Injector do
  before(:each) do
    @injector = Injector.new
  end

  def implementation_for(interface, &block)
    klass = Class.new(&block)
    klass.class_eval "def #{interface}?; true; end"
    klass
  end

  def with_binding(interface, &block)
    klass = implementation_for(interface, &block)
    @injector.bind(interface).to(klass)
  end

  def with_cached_binding(interface, &block)
    klass = Class.new(&block)
    @injector.bind(interface).cached.to(klass)
  end

  def an_instance_of(interface, &block)
    instance = @injector[interface]
    block.call(instance)
  end

  it 'should blow up if there is no binding for a class' do
    lambda { @injector[:foo] }.should raise_error(NotFound)
  end

  it 'should find a class that has used the inject keyword' do
    with_binding(:klass) { inject }
    an_instance_of :klass do |obj|
      obj.should_not be_nil
      obj.should be_klass
    end
  end

  it 'should pass in dependencies' do
    with_binding(:foo) { inject }
    with_binding(:bar) { inject }
    with_binding(:klass) do
      inject :foo => :foo, :bar => :bar
      attr_reader :foo, :bar
    end

    an_instance_of :klass do |k|
      k.should be_klass
      k.foo.should be_foo
      k.bar.should be_bar
    end
  end

  it 'should call #after_initialize after dependencies are set' do
    with_binding(:klass) do
      inject
      attr_reader :foo

      def after_initialize
        @foo = []
      end
    end

    an_instance_of :klass do |k|
      k.foo.should be_empty
    end
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
    with_binding(:klass1) { inject }
    with_binding(:klass2) { inject :one => :klass1; attr_reader :one }
    with_binding(:klass3) { inject :two => :klass2; attr_reader :two }

    an_instance_of :klass3 do |k|
      k.two.one.should be_klass1
    end
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
    with_binding(:klass1) { inject :x => :klass3 }
    with_binding(:klass2) { inject :x => :klass1 }
    with_binding(:klass3) { inject :x => :klass2 }

    lambda { @injector[:klass1] }.should raise_error(CircularDependency)
  end

  it 'should give me a new instance every time by default' do
    klass = Class.new { inject }
    injector = Injector.new {|i| i.bind(:klass).to(klass) }
    injector[:klass].should_not == injector[:klass]
  end

  it 'should give me a cached instance if I tell it to' do
    klass = Class.new { inject }
    @injector.bind(:klass).cached.to(klass)
    @injector[:klass].should == @injector[:klass]
  end

  describe 'with caching enabled and circular dependencies' do
    before (:each) do
      with_cached_binding(:klass1) { inject :two => :klass2; attr_reader :two }
      with_binding(:klass2) { inject :one => :klass1; attr_reader :one }
    end

    it 'should not blow up' do
      lambda { @injector[:klass1] }.should_not raise_error
    end

    it 'should have circular references' do
      an_instance_of :klass1 do |one|
        one.should respond_to(:two)
        one.two.should respond_to(:one)
        one.two.one.should respond_to(:two)
        one.two.one.two.should == one.two
      end
    end
  end

  it 'cannot bind more than one implementation for an interface' do
    with_binding(:klass) { inject }
    another_klass = Class.new { inject }
    lambda { @injector.bind(:klass).to(another_klass) }.should raise_error(AlreadyBound)
  end

  it 'can bind a specific instance' do
    @injector.bind(:db_user).to_instance("bob")
    an_instance_of :db_user do |obj|
      obj.should == "bob"
    end
  end

  it 'should bind providers' do
    with_binding(:klass1) { inject }
    with_binding(:klass2) do
      inject :provider => :klass1.provider
      attr_reader :provider
    end

    an_instance_of :klass2 do |obj|
      obj.provider.should respond_to(:get_instance)
      obj.provider.get_instance.should be_klass1
    end
  end
end
