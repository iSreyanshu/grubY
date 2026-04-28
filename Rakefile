require "rake/clean"

APP_ROOT = File.expand_path(__dir__)

CLEAN.include(*Dir["*.gem"])

desc "Build gem package"
task :build do
  sh "gem build grubY.gemspec"
end

desc "Install built gem locally"
task install_local: :build do
  gem_file = Dir["grubY-*.gem"].max_by { |f| File.mtime(f) }
  abort "No gem package found" unless gem_file

  sh "gem install #{gem_file}"
end

desc "Install Ruby dependencies"
task :bundle_install do
  sh "bundle install"
end

desc "Prepare Ruby dependencies"
task setup: [:bundle_install]

namespace :ci do
  desc "Minimal smoke check for gem load"
  task :smoke do
    ruby "-e", "require_relative 'lib/grubY'; puts 'grubY load ok'"
  end
end

namespace :tdlib do
  desc "Generate tdlib.json in project root (override via SRC, VERSION, COMMIT, OUT env vars)"
  task :generate_json do
    src = ENV.fetch("SRC", "https://raw.githubusercontent.com/tdlib/td/refs/heads/master/td/generate/scheme/td_api.tl")
    version = ENV.fetch("VERSION", "")
    commit = ENV.fetch("COMMIT", "")
    out = ENV.fetch("OUT", File.join(APP_ROOT, "tdlib.json"))

    ruby "scripts/generate-tdlib-json.rb",
         "--src", src,
         "--version", version,
         "--commit", commit,
         "--out", out
  end
end

task default: :build
