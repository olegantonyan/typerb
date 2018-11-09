require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

Rake::Task['release'].enhance do
  spec = Gem::Specification::load(Dir.glob('*.gemspec').first)
  sh "gem push pkg/#{spec.name}-#{spec.version}.gem"
end


task :default => :spec
