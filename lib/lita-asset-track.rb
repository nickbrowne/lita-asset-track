require 'lita'
require 'lita-timing'
require 'uri'
require 'json'
require 'net/http'

module Lita
  module Handlers
    class AssetTrack < Handler
      MINUTE = 60
      HOUR = 60 * 60
      MANIFEST_SET_KEY = "lita-asset-track-manifest"
      EXTENSIONS = ["css", "js"]

      route(/^asset\strack\slist/i, :list, command: true, help: { "asset track list" => "Lists tracked manifests" })
      route(/^asset\strack\sadd\s+(.+)/i, :add, command: true, help: { "asset track add [url]" => "Provide one or more urls to a manifest.json to start tracking asset sizes in librato"})
      route(/^asset\strack\sremove\s+(.+)/i, :remove, command: true, help: { "asset track remove [url]" => "Stop tracking one or more existing manifest.json urls"})

      on :loaded, :start_timer

      def start_timer(payload)
        every(MINUTE) do
          begin
            Lita::Timing::RateLimit.new("lita-asset-track", redis).once_every(HOUR) do
              redis.sscan_each(MANIFEST_SET_KEY).map { |manifest_url|
                URI(manifest_url)
              }.each { |manifest_uri|
                manifest_json = JSON.parse Net::HTTP.get(manifest_uri)

                manifest_json.select { |k, v|
                  k.match /\.(#{EXTENSIONS.join("|")})$/
                }.map { |asset_name, asset_path|
                  asset_uri = determine_asset_uri(manifest_uri, asset_path)

                  Net::HTTP.start(asset_uri.host, asset_uri.port) { |http|
                    robot.trigger(:asset_track_size,
                      host: manifest_uri.host,
                      asset: asset_name,
                      bytes: bytes(http, asset_uri.path),
                      bytes_gzip: bytes_gzip(http, asset_uri.path),
                    )
                  }
                }
              }
            end
          rescue StandardError => e
            $stderr.puts "Error in timer loop: #{e.class} #{e.message} #{e.backtrace.first}"
          end
        end
      end

      def list(response)
        manifests = redis.sscan_each(MANIFEST_SET_KEY).to_a

        if manifests.any?
          response.reply("Tracking:\n\t#{manifests.join("\n\t")}\n")
        else
          response.reply("Not tracking any manifests.")
        end
      end

      def add(response)
        urls = URI.extract(response.args.join(" "))

        valid, invalid = urls.partition do |url|
          url.end_with? "manifest.json"
        end

        response.reply("URLs must point to manifest.json, skipping: \n#{invalid.join("\n")}") if invalid.any?

        redis.sadd(MANIFEST_SET_KEY, valid)
        total = redis.scard(MANIFEST_SET_KEY)

        response.reply("Added #{valid.count} URLs. Now tracking #{total} in total.")
      rescue
        response.reply("give proper url pls")
      end

      def remove(response)
        redis.srem(MANIFEST_SET_KEY, URI.extract(response.args.join(" ")))
        response.reply("Done")
      rescue
        response.reply("give proper url pls")
      end

      private

      def determine_asset_uri(manifest_uri, asset_path)
        if asset_path =~ URI::regexp
          URI(asset_path)
        else
          URI::HTTP.build({
            host: manifest_uri.host,
            scheme: manifest_uri.scheme,
            path: asset_path
          })
        end
      end

      def bytes(http, path)
        http.head(path)["content-length"]
      end

      def bytes_gzip(http, path)
        http.head(path, "accept-encoding" => "gzip")["content-length"]
      end

      Lita.register_handler(self)
    end
  end
end
