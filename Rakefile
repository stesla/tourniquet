GEM = 'tourniquet'
GEM_VERSION = '0.1'
AUTHOR = 'Samuel Tesla'
EMAIL = 'samuel.tesla@gmail.com'
HOMEPAGE = 'http://github.com/stesla/tourniquet'
SUMMARY = 'a declarative dependency injection framework for Ruby'

task :default => 'spec:technical'

begin
  require 'spec/rake/spectask'
  namespace :spec do
    desc "Run technical specs (default)"
    Spec::Rake::SpecTask.new(:technical) do |t|
      t.spec_opts << %w(-fs --color)
    end
  end
rescue LoadError
  abort "You need to install rspec to run the specs: gem install rspec"
end


begin
  require 'rubygems'
  require 'rake/gempackagetask'
rescue LoadError
  # No gems for you
else
  gemspec = Gem::Specification.new do |s|
    s.name = GEM
    s.version = GEM_VERSION
    s.platform = Gem::Platform::RUBY
    s.summary = SUMMARY

    s.files = `git ls-files`.split("\n")
    s.require_path = 'lib'
    s.has_rdoc = true
    s.extra_rdoc_files = ["README"]
    s.test_files = Dir['spec/**/*.rb']
    
    s.author = AUTHOR
    s.email = EMAIL
    s.homepage = HOMEPAGE

    s.add_development_dependency 'rspec'
  end

  Rake::GemPackageTask.new(gemspec) do |pkg|
    pkg.need_tar = true
    pkg.need_zip = true
  end

  desc "install gem"
  task :install => :gem do
    sh "gem install pkg/#{GEM}-#{GEM_VERSION}.gem --no-update-sources --no-rdoc"
  end
end
