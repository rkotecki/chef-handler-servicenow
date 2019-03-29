Gem::Specification.new do |s|
  s.name = 'chef-handler-servicenow'
  s.version = '1.1.1'
  s.platform = Gem::Platform::RUBY
  s.summary = 'Chef report handler to report resources updated in the Chef Run'
  s.description = s.summary
  s.author = 'Ryan Kotecki'
  s.email = 'ryankotecki@company.com'
  s.homepage = 'http://github.com/your_org/chef-handler-servicenow'
  s.require_path = 'lib'
  s.files = %w(LICENSE README.md) + Dir.glob('lib/**/*')
end
