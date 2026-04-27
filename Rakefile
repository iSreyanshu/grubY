require "rake/clean"

APP_ROOT = File.expand_path(__dir__)
PY_REQ = File.join(APP_ROOT, "example", "requirements.txt")
VENV_PATH = File.join(APP_ROOT, ".venv")

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

desc "Install python deps for NTgCalls demo (virtualenv)"
task :python_setup do
  unless File.exist?(PY_REQ)
    puts "No #{PY_REQ} found, skipping python setup"
    next
  end

  python_cmd = ENV["PYTHON"] || "python"
  sh "#{python_cmd} -m venv #{VENV_PATH}" unless Dir.exist?(VENV_PATH)

  pip_path = if Gem.win_platform?
               File.join(VENV_PATH, "Scripts", "pip.exe")
             else
               File.join(VENV_PATH, "bin", "pip")
             end

  sh "#{pip_path} install -r #{PY_REQ}"
end

desc "Install Ruby dependencies"
task :bundle_install do
  sh "bundle install"
end

desc "Prepare both Ruby and Python dependencies"
task setup: [:bundle_install, :python_setup]

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
