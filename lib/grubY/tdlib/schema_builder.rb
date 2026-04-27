require "json"
require "net/http"
require "uri"
require "cgi"
require "stringio"

module GrubY
  module TDLib
    class SchemaBuilder
      TL_DEF_REGEX = /^(?<name>\w+)(?:#[0-9a-f]+)?\s+(?<params>.*)=\s+(?<type>\w+);$/
      PARAM_DETAIL_REGEX = /(?<name>\w+):(?<type>[^\s]+)/
      ROW_REGEX = /<tr>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<td>(.*?)<\/td>\s*<\/tr>/m
      TAG_REGEX = /<[^>]*>/

      def initialize(src:, version: "", commit: "", out: "tdlib.json")
        @src = src
        @version = version
        @commit = commit
        @out = out
      end

      def call
        data = if @src.start_with?("http://", "https://")
                 fetch_and_parse_tl(@src)
               else
                 parse_tl_from_file(@src)
               end

        data["version"] = @version
        data["commit"] = @commit

        begin
          data["options"] = fetch_options
        rescue StandardError => e
          warn "Warning: failed to fetch options: #{e.message}"
        end

        save_json(data, @out)
      end

      private

      def parse_tl_from_file(path)
        File.open(path, "r:utf-8") do |file|
          parse_tl_from_reader(file)
        end
      end

      def fetch_and_parse_tl(url)
        uri = URI.parse(url)
        request = Net::HTTP::Get.new(uri)
        request["User-Agent"] = "gruby-tdlib-schema-builder/1.0"

        response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", read_timeout: 30, open_timeout: 30) do |http|
          http.request(request)
        end
        raise "failed to fetch #{url}: status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        parse_tl_from_reader(StringIO.new(response.body))
      end

      def parse_tl_from_reader(reader)
        data = {
          "name" => "Auto-generated JSON TDLib API",
          "version" => "",
          "commit" => "",
          "classes" => {},
          "types" => {},
          "updates" => {},
          "functions" => {},
          "options" => {}
        }

        current_description = ""
        current_params = {}
        is_functions_section = false
        start = false

        reader.each_line do |raw_line|
          line = raw_line.strip

          if line.include?("---functions---")
            is_functions_section = true
            next
          end

          if line.start_with?("//")
            start = true
            if line.start_with?("//@")
              parse_doc_tags(data, line.sub("//@", ""), current_params) do |description|
                current_description = [current_description, description].reject(&:empty?).join(" ").strip
              end
            end
            next
          end

          next if line.empty? || !start

          match = TL_DEF_REGEX.match(line)
          next unless match

          name = match[:name]
          params_str = match[:params]
          result_type = match[:type]

          type_def = {
            "description" => current_description,
            "args" => {},
            "type" => result_type
          }

          params_str.scan(PARAM_DETAIL_REGEX) do |p_name, p_type|
            p_desc = current_params[p_name] || ""
            type_def["args"][p_name] = {
              "description" => p_desc,
              "is_optional" => optional_arg?(p_desc, p_type),
              "type" => p_type
            }
          end

          if is_functions_section
            data["functions"][name] = type_def
            (data["classes"][result_type] ||= default_class)["functions"] << name
          elsif name.start_with?("update")
            data["updates"][name] = type_def
            (data["classes"][result_type] ||= default_class)["types"] << name
          else
            data["types"][name] = type_def
            (data["classes"][result_type] ||= default_class)["types"] << name
          end

          current_description = ""
          current_params = {}
        end

        data
      end

      def parse_doc_tags(data, tag_line, current_params)
        parts = (" " + tag_line).split(" @")
        current_class = nil

        parts.each do |part|
          part = part.strip
          next if part.empty?

          tag_name, tag_text = part.split(" ", 2)
          tag_text = (tag_text || "").strip

          case tag_name
          when "class"
            current_class = tag_text
          when "description"
            if current_class
              data["classes"][current_class] = {
                "description" => tag_text,
                "types" => [],
                "functions" => []
              }
              current_class = nil
            else
              yield(tag_text)
            end
          else
            clean_name = tag_name.sub(/^param_/, "")
            current_params[clean_name] = [current_params[clean_name], tag_text].compact.join(" ").strip
          end
        end
      end

      def default_class
        { "description" => "", "types" => [], "functions" => [] }
      end

      def optional_arg?(description, type)
        text = description.to_s.downcase
        text.include?("may be null") ||
          text.include?("pass null") ||
          text.include?("may be empty") ||
          description.to_s.include?("If non-empty,") ||
          type.to_s.include?("?")
      end

      def fetch_options
        url = URI.parse("https://core.telegram.org/tdlib/options")
        request = Net::HTTP::Get.new(url)
        request["User-Agent"] = "gruby-tdlib-schema-builder/1.0"

        response = Net::HTTP.start(url.host, url.port, use_ssl: true, read_timeout: 30, open_timeout: 30) do |http|
          http.request(request)
        end
        raise "failed to fetch options: status #{response.code}" unless response.is_a?(Net::HTTPSuccess)

        content = response.body
        marker_index = content.index("list-of-options-supported-by-tdlib")
        raise "could not find options list in HTML" unless marker_index

        options = {}
        content[marker_index..].scan(ROW_REGEX) do |name, type_name, writable, description|
          clean_name = clean_html(name)
          next if clean_name.empty? || clean_name.casecmp("name").zero?

          options[clean_name] = {
            "type" => map_type(clean_html(type_name)),
            "writable" => clean_html(writable).casecmp("yes").zero?,
            "description" => clean_html(description)
          }
        end

        raise "no options were parsed from HTML" if options.empty?

        options
      end

      def clean_html(text)
        CGI.unescapeHTML(text.gsub(TAG_REGEX, "").strip)
      end

      def map_type(type_name)
        case type_name
        when "Integer"
          "int64"
        when "Boolean"
          "Bool"
        when "String"
          "string"
        else
          type_name
        end
      end

      def save_json(data, path)
        File.write(path, JSON.pretty_generate(data) + "\n")
      end
    end
  end
end
