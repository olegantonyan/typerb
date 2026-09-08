# frozen_string_literal: true

require_relative 'lib/typerb/version'

Gem::Specification.new do |spec|
  spec.name          = 'typerb'
  spec.version       = Typerb::VERSION
  spec.authors       = ['Oleg Antonyan']
  spec.email         = ['oleg.b.antonyan@gmail.com']

  spec.summary       = 'Typecheck sugar for Ruby.'
  spec.description   = 'Refinement adding type!, not_nil!, respond_to!, enum! and subset_of! assertions that name the variable they failed on.'
  spec.homepage      = 'https://github.com/olegantonyan/typerb'
  spec.license       = 'MIT'

  spec.files         = Dir['lib/**/*.rb'] + %w[README.md CHANGELOG.md LICENSE.txt CODE_OF_CONDUCT.md]
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 3.0'

  spec.metadata = {
    'source_code_uri' => spec.homepage,
    'changelog_uri' => "#{spec.homepage}/blob/master/CHANGELOG.md",
    'bug_tracker_uri' => "#{spec.homepage}/issues",
    'rubygems_mfa_required' => 'true'
  }
end
