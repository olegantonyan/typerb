# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'typerb/version'

Gem::Specification.new do |spec|
  spec.name          = 'typerb'
  spec.version       = Typerb::VERSION
  spec.authors       = ['Oleg Antonyan']
  spec.email         = ['oleg.b.antonyan@gmail.com']

  spec.summary       = 'Typecheck sugar for Ruby.'
  spec.description   = 'Typecheck sugar for Ruby.'
  spec.homepage      = 'https://github.com/olegantonyan/typerb'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '>= 1.17'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rspec', '>= 3.0'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'super_awesome_print'

  spec.required_ruby_version = '>= 2.4'
end
