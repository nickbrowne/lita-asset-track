require 'redis'
require 'lita-asset-track'

RSpec.describe Lita::Handlers::AssetTrack, lita_handler: true do
  let(:handler) { Lita::Handlers::AssetTrack.new(robot) }
  let(:redis_double) { instance_double(Redis) }
  let(:response_double) { instance_double(Lita::Response) }

  # stub out redis
  before { allow(handler).to receive(:redis).and_return(redis_double) }

  it "responds to 'asset track list'" do
    expect(handler).to route("lita asset track list").to(:list)
  end

  it "responds to 'asset track add'" do
    expect(handler).to route("lita asset track add xxx").to(:add)
  end

  it "responds to 'asset track remove'" do
    expect(handler).to route("lita asset track remove xxx").to(:remove)
  end

  describe "#start_timer" do
    it "sets a timer to run every hour" do
      expect(handler).to receive(:every).with(60)
      handler.start_timer(nil)
    end
  end

  describe "#list" do
    context "no manifests" do
      it "tells the user" do
        expect(redis_double).to receive(:sscan_each).and_return []
        expect(response_double).to receive(:reply).with "Not tracking any manifests."

        handler.list(response_double)
      end
    end

    context "more than zero manifests in set" do
      it "lists them to the user" do
        expect(redis_double).to receive(:sscan_each).and_return ["https://example.com/manifest.json", "https://bing.com/manifest.json"]
        expect(response_double).to receive(:reply).with <<~TEXT
          Tracking:
          \thttps://example.com/manifest.json
          \thttps://bing.com/manifest.json
        TEXT

        handler.list(response_double)
      end
    end
  end

  describe "#add" do
    context "valid url" do
      it "adds it to the set" do
        expect(response_double).to receive(:args).and_return ["https://theconversation.com/assets/manifest.json"]
        expect(response_double).to receive(:reply).with("Added 1 URLs. Now tracking 5 in total.")
        expect(redis_double).to receive(:scard).and_return 5
        expect(redis_double).to receive(:sadd).with("lita-asset-track-manifest", ["https://theconversation.com/assets/manifest.json"])

        handler.add(response_double)
      end
    end

    context "invalid url" do
      it "informs the user of their grievous error" do
        expect(response_double).to receive(:args).and_return ["http://example.com/image.jpg"]
        expect(response_double).to receive(:reply).with("URLs must point to manifest.json, skipping: \nhttp://example.com/image.jpg")
        expect(response_double).to receive(:reply).with("Added 0 URLs. Now tracking 5 in total.")
        expect(redis_double).to receive(:scard).and_return 5
        expect(redis_double).to receive(:sadd).with("lita-asset-track-manifest", [])

        handler.add(response_double)
      end
    end
  end

  describe "#remove" do
    context "valid urls" do
      let(:urls) { ["http://example.com/manifest.json", "http://fun.com/manifest.json"] }

      it "is removed from the set" do
        expect(response_double).to receive(:args).and_return urls
        expect(response_double).to receive(:reply).with("Done")
        expect(redis_double).to receive(:srem).with("lita-asset-track-manifest", urls)

        handler.remove(response_double)
      end
    end

    context "invalid urls" do
      let(:urls) { ["rubbish", "🍾"] }

      it "does nothing" do
        expect(response_double).to receive(:args).and_return urls
        expect(response_double).to receive(:reply).with("Done")
        expect(redis_double).to receive(:srem).with("lita-asset-track-manifest", [])

        handler.remove(response_double)
      end
    end
  end
end
