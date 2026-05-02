require "json"

module GrubY
  class Session
    FILE = "storage/sessions.json"

    def initialize
      Dir.mkdir("storage") unless Dir.exist?("storage")
      File.write(FILE, "{}") unless File.exist?(FILE)
      @data = JSON.parse(File.read(FILE))
    end

    def get(user_id)
      @data[user_id.to_s] ||= {}
    end

    def set(user_id, value)
      @data[user_id.to_s] = value
      save
    end

    def save
      File.write(FILE, JSON.pretty_generate(@data))
    end

    def to_h
      @data.dup
    end
  end
end
