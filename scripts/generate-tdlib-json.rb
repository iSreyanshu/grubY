#!/usr/bin/env ruby

require "optparse"
require_relative "../lib/gruubY/tdlib/schema_builder"

options = {
  src: "https://raw.githubusercontent.com/tdlib/td/refs/heads/master/td/generate/scheme/td_api.tl",
  version: "",
  commit: "",
  out: "tdlib.json"
}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby scripts/generate-tdlib-json.rb [options]"

  opts.on("--src SRC", "Path to TL file or URL") { |v| options[:src] = v }
  opts.on("--version VERSION", "TDLib version") { |v| options[:version] = v }
  opts.on("--commit COMMIT", "TDLib commit hash") { |v| options[:commit] = v }
  opts.on("--out OUT", "Output JSON file path") { |v| options[:out] = v }
end.parse!

builder = GrubY::TDLib::SchemaBuilder.new(
  src: options[:src],
  version: options[:version],
  commit: options[:commit],
  out: options[:out]
)

builder.call
puts "TDLib JSON generated at #{options[:out]}"
