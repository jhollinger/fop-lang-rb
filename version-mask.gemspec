require_relative 'lib/version_mask/version'

Gem::Specification.new do |s|
  s.name = 'version_mask'
  s.version = VersionMask::VERSION
  s.licenses = ['MIT']
  s.summary = 'A micro expression language'
  s.description = 'A micro expression language for matching and modifying text'
  s.date = '2021-08-15'
  s.authors = ['Jordan Hollinger']
  s.email = 'jordan.hollinger@gmail.com'
  s.homepage = 'https://jhollinger.github.io/version-mask/'
  s.require_paths = ['lib']
  s.files = [Dir.glob('lib/**/*'), 'README.md'].flatten
  s.required_ruby_version = '>= 2.3.0'
end
