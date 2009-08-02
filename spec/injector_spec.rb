$:.unshift File.join(File.dirname(__FILE__), '..', 'lib')
require 'tourniquet'

include Tourniquet

describe Tourniquet::Injector do
  before (:each) do
    Injector.reset_instance
  end
  
  it 'should blow up if there is no binding for a class' do
    lambda { Injector[String] }.should raise_error(Injector::NotFound)
  end

  it 'should find a class that has used the inject keyword' do
    klass = Class.new { inject }
    Injector[klass].class.should == klass
  end

  it 'should pass in dependencies' do
    dep_foo = Class.new { inject }
    dep_bar = Class.new { inject }

    klass = Class.new do
      inject :foo => dep_foo, :bar => dep_bar
      attr_reader :foo, :bar
    end

    k = Injector[klass]
    k.class.should == klass
    k.foo.should_not be_nil
    k.foo.class.should == dep_foo
    k.bar.should_not be_nil
    k.bar.class.should == dep_bar
  end

  it 'should call #after_initialize after dependencies are set' do
    dep = Class.new { inject }

    klass = Class.new do
      inject :dep => dep
      attr_reader :foo

      def after_initialize
        @foo = @dep
      end
    end

    k = Injector[klass]
    k.foo.should_not be_nil
    k.foo.class.should == dep
  end
end
