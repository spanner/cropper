# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "cropper/version"

Gem::Specification.new do |s|
  s.name        = "cropper"
  s.version     = Cropper::VERSION
  s.authors     = ["William Ross"]
  s.email       = ["will@spanner.org"]
  s.homepage    = ""
  s.summary     = %q{A simple but specific way to attach (re)croppable uploads to any model}
  s.description = %q{Provides a mechanism for uploading, cropping and reusing images in any of your models.}

  s.rubyforge_project = "cropper"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rails", "~> 3.2.0"
  s.add_dependency('paperclip', '~> 3.3')
  s.add_dependency('delayed_job_active_record')

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec-rails"
  s.add_development_dependency "shoulda-matchers"
  s.add_development_dependency "capybara"
  s.add_development_dependency "acts_as_fu"
  s.add_development_dependency "sqlite3"
  
end
