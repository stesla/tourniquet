require '../lib/injector'

describe Injector do
  before (:each) do
    @injector = Injector.new
  end
  
  it 'should blow up if there is no binding for a class' do
    lambda { @injector[String] }.should raise_error(Injector::NotFound)
  end

  it 'should find a class that has used the inject keyword' do
    klass = Class.new { inject }
    @injector[klass].class.should == klass
  end

  it 'should pass in dependencies' do
    dep_foo = Class.new { inject }
    dep_bar = Class.new { inject }

    klass = Class.new do
      inject :foo => dep_foo, :bar => dep_bar
      attr_reader :foo, :bar
    end

    k = @injector[klass]
    k.class.should == klass
    k.foo.should_not be_nil
    k.foo.class.should == dep_foo
    k.bar.should_not be_nil
    k.bar.class.should == dep_bar
  end
end
