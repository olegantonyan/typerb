require 'bundler/gem_tasks'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)

# Let bundler's release task do its job, minus the push to Rubygems,
# and after it completes, use "gem inabox" to publish the gem to our
# internal gem server.
Rake::Task['release'].enhance do
  spec = Gem::Specification::load(Dir.glob('*.gemspec').first)
  sh "gem inabox pkg/#{spec.name}-#{spec.version}.gem"
end


task :default => :spec
