require "net/http"

module GrubY
  class FileStream
    def self.download(url, dest)
      uri = URI(url)

      Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
        http.request_get(uri) do |res|
          File.open(dest, "wb") do |f|
            res.read_body { |chunk| f.write(chunk) }
          end
        end
      end
    end
  end
end
