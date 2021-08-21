require_relative 'lib/fop/version'

Gem::Specification.new do |s|
  s.name = 'fop_lang'
  s.version = Fop::VERSION
  s.licenses = ['MIT']
  s.summary = 'A micro expression language'
  s.description = 'A micro expression language for Filter and OPerations on text'
  s.date = '2021-08-20'
  s.authors = ['Jordan Hollinger']
  s.email = 'jordan.hollinger@gmail.com'
  s.homepage = 'https://jhollinger.github.io/fop-lang-rb/'
  s.require_paths = ['lib']
  s.files = [Dir.glob('lib/**/*'), 'README.md'].flatten
  s.executables << 'fop'
  s.required_ruby_version = '>= 2.3.0'
end
