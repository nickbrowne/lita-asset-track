# lita-asset-track

Tracks webpack asset sizes referenced by `manifest.json`.

Allows you to register manifests and will emit hourly events with the size of each JS or CSS files.

## Usage

Add to your Gemfile:
```ruby
gem 'lita-asset-track'
```

Set up an event handler.
```ruby
on(:asset_track_size) do |payload|
  puts payload[:host]
  puts payload[:asset]
  puts payload[:size]
end
```

Register webpack manifests.
```
lita asset track add http://app1.com/manifest.json http://app2.com/manifest.json
```

Your subscribed block will be called roughly every hour. You can do what you want
with the stats, but the intention is to use some third party service like Librato
or Datadog to track size over time.


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
