# lita-asset-track

Tracks webpack asset sizes referenced by `manifest.json`.

Allows you to register manifests and will emit hourly events with the size of each JS or CSS files.

## Usage

Add to your Gemfile:
```ruby
gem 'lita-asset-track'
```

Create a lita event handler.
```ruby
require "lita-asset-track"
require "lita"

module Lita
  module Handlers
    # Subscribe to event from lita-asset-track and print the data
    class AssetSize < Handler
      on(:asset_track_size) do |payload|
        msg  = "host: #{payload[:host]}\n"
        msg += "asset: #{payload[:asset]}"
        msg += "bytes: #{payload[:bytes]}"
        msg += "bytes_gzip: #{payload[:bytes_gzip]}"
        robot.send_message(target_room, msg)
      end

      private

      def target_room
        Source.new(room: Lita::Room.find_by_name("general"))
      end
    end

    Lita.register_handler(AssetSize)
  end
end
```

### Chat Commands

Register webpack manifests:

```
lita asset track add http://app1.com/manifest.json http://app2.com/manifest.json
```

Your subscribed block will be called roughly every hour. You can do what you want
with the stats, but the intention is to use some third party service like Librato
or Datadog to track size over time.

List tracked webpack manifests:

```
lita asset track list
```

Stop tracking a webpack manifests:

```
lita asset track remove http://app1.com/manifest.json
```

## Developing

Write tests, run tests:
```
bundle exec rspec
```

Try integration:
```
bundle exec lita
> lita help
```

## License

MIT
