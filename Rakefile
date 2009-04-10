RAILS_ROOT = "#{File.dirname(__FILE__)}"

require 'rubygems'
require 'spec/rake/spectask'

require 'config/environment'

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

require 'tasks/rails'

Spec::Rake::SpecTask.new do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.spec_opts = ['--format', 'profile', '--color']
end

Spec::Rake::SpecTask.new(:coverage) do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_opts = ['-x', 'spec,gems']
end

desc "Default task is to run specs"
task :default => :spec

desc 'Generate documentation for the acts_as_most_popular plugin.'
Rake::RDocTask.new(:rdoc) do |rdoc|
  rdoc.rdoc_dir = 'rdoc'
  rdoc.title    = 'ActsAsMostPopular'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
