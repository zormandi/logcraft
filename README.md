# Logcraft

[![Build Status](https://github.com/zormandi/logcraft/actions/workflows/main.yml/badge.svg)](https://github.com/zormandi/logcraft/actions/workflows/main.yml)

Logcraft is a zero-configuration structured logging library for pure Ruby or [Ruby on Rails](https://rubyonrails.org/)
applications. It is the successor to [Ezlog](https://github.com/emartech/ezlog) with which it shares its ideals but is
reimagined and reimplemented to be more versatile and much more thoroughly tested.

Logcraft's purpose is threefold:

1. Make sure that our applications are logging in a concise and sensible manner; emitting no unnecessary "noise" but
   containing all relevant and necessary information (like timing or a request ID).
2. Make sure that all log messages are written to STDOUT in a machine-processable format (JSON).
3. Achieving the above goals should require no configuration in the projects where the library is used.

Logcraft supports:

* [Ruby](https://www.ruby-lang.org) 2.6 and up (tested with 2.6, 2.7, 3.0 and 3.1)
* [Rails](https://rubyonrails.org/) 5 and up (tested with 5.2, 6.0 and 6.1)
* [Sidekiq](https://github.com/mperham/sidekiq) support is coming soon via a separate gem (_logcraft-sidekiq_)

Logcraft uses Tim Pease's wonderful [Logging](https://github.com/TwP/logging) gem under the hood for an all-purpose
structured logging solution.

## Installation

### Rails

Add this line to your application's Gemfile:

```ruby
gem 'logcraft'
```

Although Logcraft sets up sensible defaults for all logging configuration settings, it leaves you the option to override
these settings manually in the way you're used to; via Rails's configuration mechanism. Unfortunately the Rails new
project generator automatically generates code for the production environment configuration that overrides some of these
default settings.

For Logcraft to work properly, you need to delete or comment out the logging configuration options in the generated
`config/environments/production.rb` file.

### Non-Rails applications

Add this line to your application's Gemfile:

```ruby
gem 'logcraft'
```

and call

```ruby
Logcraft.initialize
```

any time during your application's startup.

## Usage

### Structured logging

Any loggers created by your application (including the `Rails.logger`) will automatically be configured to write
messages in JSON format to the standard output. These loggers can handle a variety of message types:

* String
* Hash
* Exception
* any other object that can be coerced into a String

The logger also automatically adds some basic information to all messages, such as:

* name of the logger
* timestamp
* log level (as string)
* hostname
* PID

Examples:

```ruby
logger = Logcraft.logger 'Application'

logger.info 'Log message'
# => {"timestamp":"2022-06-26T17:52:57.845+02:00","level":"INFO","logger":"Application","hostname":"Zoltans-iPro","pid":80422,"message":"Log message"}

logger.info message: 'User logged in', user_id: 42
# => {"timestamp":"2022-06-26T17:44:01.926+02:00","level":"INFO","logger":"Application","hostname":"MacbookPro.local","pid":80422,"message":"User logged in","user_id":42}

logger.warn error
# Formatted for better readability (the original is a single line string):
# => {
#      "timestamp": "2022-06-26T17:46:42.418+02:00",
#      "level": "WARN",
#      "logger": "Application",
#      "hostname": "MacbookPro.local",
#      "pid": 80422,
#      "message": "wrapping error",
#      "error": {
#        "class": "StandardError",
#        "message": "wrapping error",
#        "backtrace": [...],
#        "cause": {
#          "class": "RuntimeError",
#          "message": "original error",
#          "backtrace": [...]
#        }
#      }
#    }
```

#### Adding context information to log messages

Logcraft provides two helper methods which can be used to add context information to log messages:

* `within_log_context(context)`: Starts a new log context initialized with `context` and executes the provided block
  within that context. Once execution is finished, the log context is cleaned up and the previous context (if any) is
  reinstated. In practice, this means that every time we log something (within the block), the log message will include
  the information that's in the current context. This can be useful for storing request-specific information
  (request ID, user ID, ...) in the log context early on (for example in a middleware) and not have to worry about
  including it every time we want to log a message.

  Example:

  ```ruby
  within_log_context customer_id: 1234 do
    logger.info 'test 1'
  end
  logger.info 'test 2'
  
  #=> {...,"level":"INFO","customer_id":1234,"message":"test 1"}
  #=> {...,"level":"INFO","message":"test 2"}
  ```

* `add_to_log_context(context)`: Adds the provided `context` to the current log context but provides no mechanism for
  removing it later. Only use this method if you are sure that you're working within a specific log context and that it
  will be cleaned up later (e.g. by only using this method in a block passed to the previously explained
  `within_log_context` method).

You can access these methods either in the global scope by calling them via `Logcraft.within_log_context` and
`Logcraft.add_to_log_context` or locally by including the `Logcraft::LogContextHelper` module into your class/module.

### Rails logging

Logcraft automatically configures Rails to provide you with structured logging capability via the `Rails.logger`.
It also changes Rails's default logging configuration to be more concise and emit less "noise".

In more detail:

* The `Rails.logger` is set up to be a Logcraft logger with the name `Application`.
* Rails's default logging of uncaught errors is modified and instead of spreading the error message across several
  lines, Logcraft log every uncaught error in 1 line (per error), including the error's name and context (stack trace,
  etc.).
* Most importantly, Rails's default request logging - which logs several lines per event during the processing of an
  action - is replaced by Logcraft's own access log middleware. The end result is an access log that
    * contains all relevant information (request ID, method, path, params, client IP, duration and
      response status code), and
    * has 1 log line per request, logged at the end of the request.

Thanks to Mathias Meyer for writing [Lograge](https://github.com/roidrage/lograge), which inspired the solution.
If Logcraft is not your cup of tea but you're looking for a way to tame Rails's logging then be sure to check out
[Lograge](https://github.com/roidrage/lograge).

```
GET /welcome?subsession_id=34ea8596f9764f475f81158667bc2654

With default Rails logging:

Started GET "/welcome?subsession_id=34ea8596f9764f475f81158667bc2654" for 127.0.0.1 at 2022-06-26 18:07:08 +0200
Processing by PagesController#welcome as HTML
  Parameters: {"subsession_id"=>"34ea8596f9764f475f81158667bc2654"}
  Rendering pages/welcome.html.haml within layouts/application
  Rendered pages/welcome.html.haml within layouts/application (5.5ms)
Completed 200 OK in 31ms (Views: 27.3ms | ActiveRecord: 0.0ms)

With Logcraft:
{"timestamp":"2022-06-26T18:07:08.103+02:00","level":"INFO","logger":"AccessLog","hostname":"MacbookPro.local","pid":80908,"request_id":"9a43631b-284c-4677-9d08-9c1cc5c7d3a7","message":"GET /welcome?subsession_id=34ea8596f9764f475f81158667bc2654 - 200 (OK)","remote_ip":"127.0.0.1","method":"GET","path":"/welcome?subsession_id=34ea8596f9764f475f81158667bc2654","params":{"subsession_id":"34ea8596f9764f475f81158667bc2654","controller":"pages","action":"welcome"},"response_status_code":200,"duration":13,"duration_sec":0.013}

Formatted for readability:
{
  "timestamp": "2022-06-26T18:07:08.103+02:00",
  "level": "INFO",
  "logger": "AccessLog",
  "hostname": "MacbookPro.local",
  "pid": 80908, "request_id": "9a43631b-284c-4677-9d08-9c1cc5c7d3a7",
  "message": "GET /welcome?subsession_id=34ea8596f9764f475f81158667bc2654 - 200 (OK)",
  "remote_ip": "127.0.0.1",
  "method": "GET",
  "path": "/welcome?subsession_id=34ea8596f9764f475f81158667bc2654",
  "params": {
    "subsession_id": "34ea8596f9764f475f81158667bc2654",
    "controller": "pages",
    "action": "welcome"
  }, 
  "response_status_code": 200, 
  "duration": 13, 
  "duration_sec": 0.013
}
```

By default, Logcraft logs all request parameters as a hash (JSON object) under the `params` key. This is very convenient
in a structured logging system and makes it easy to search for specific request parameter values e.g. in ElasticSearch
(should you happen to store your logs there). Unfortunately, in some cases - such as when handling large forms - this
can create quite a bit of noise and impact the searchability of your logs negatively or pose a security risk or data
policy violation. You have the option to restrict the logging of certain parameters via configuration options (see the
Configuration section).

#### The log level

The logger's log level is determined as follows (in order of precedence):

* the log level set in the application's configuration (for Rails applications),
* the LOG_LEVEL environment variable, or
* `INFO` as the default log level if none of the above are set.

The following log levels are available: `DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`.

## Configuration options

### Rails

Logcraft provides the following configuration options for Rails:

| Option                                          | Default value            | Description                                                                                                               |
|-------------------------------------------------|--------------------------|---------------------------------------------------------------------------------------------------------------------------|
| logcraft.global_context                         | `{}`                     | A global log context that will be included in every log message. Must be either a Hash or a lambda/Proc returning a Hash. |
| logcraft.layout_options                         | `{}`                     | Custom options for the log layout. Currently only the `level_formatter` option is supported (see examples).               |
| logcraft.access_log.logger_name                 | `'AccessLog'`            | The name of the logger emitting access log messages.                                                                      |
| logcraft.access_log.exclude_paths               | `[]`                     | A list of paths (array of strings or RegExps) not to include in the access log.                                           |
| logcraft.access_log.log_only_whitelisted_params | `false`                  | If `true`, the access log will only contain whitelisted parameters.                                                       |
| logcraft.access_log.whitelisted_params          | `[:controller, :action]` | The only parameters to be logged in the access log if whitelisting is enabled.                                            |

Examples:

```ruby
# Use these options in your Rails configuration files (e.g. application.rb)

# Set up a global context you want to see in every log message
config.logcraft.global_context = -> do
  {
    environment: ENV['RAILS_ENV'],
    timestamp_linux: Time.current.to_i # evaluated every time when emitting a log message
  }
end

# Set up a custom log level formatter (e.g. Ougai-like numbers)
config.logcraft.layout_options = {
  level_formatter: ->(level_number) { (level_number + 2) * 10 }
}
Rails.logger.error('Boom!')
# => {...,"level":50,"message":"Boom!"}

# Exclude healthcheck and monitoring URLs from your access log:
config.logcraft.exclude_paths = ['/healthcheck', %r(/monitoring/.*)]

# Make sure no sensitive data is logged by accident in the access log, so only log controller and action:
config.logcraft.log_only_whitelisted_params = true
```

### Non-Rails

The `global_context` and `layout_options` configuration options (see above) are available to non-Rails projects
via Logcraft's initialization mechanism. You can also set the default log level this way.

```ruby
Logcraft.initialize log_level: :info, global_context: {}, layout_options: {}
```

## Integration with DataDog

You can set up tracing with [DataDog](https://www.datadoghq.com/) by providing an initial context to be included in
every log message:

```ruby
config.logcraft.global_context = -> do
  return unless Datadog::Tracing.enabled?

  correlation = Datadog::Tracing.correlation
  {
    dd: {
      trace_id: correlation.trace_id.to_s,
      span_id: correlation.span_id.to_s,
      env: correlation.env.to_s,
      service: correlation.service.to_s,
      version: correlation.version.to_s
    },
    ddsource: ['ruby']
  }
end
```

## RSpec support

Logcraft comes with built-in support for testing your logging activity using [RSpec](https://rspec.info/).
To enable spec support for Logcraft, put this line in your `spec_helper.rb` or `rails_helper.rb`:

```ruby
require 'logcraft/rspec'
```

What you get:

* Helpers
    * `log_output` provides access to the complete log output (array of strings) in your specs
    * `log_output_is_expected` shorthand for writing expectations for the log output
* Matchers
    * `include_log_message` matcher for expecting a certain message in the log output
    * `log` matcher for expecting an operation to log a certain message

```ruby
# Check that the log output contains a certain message
expect(log_output).to include_log_message message: 'Test message'
log_output_is_expected.to include_log_message message: 'Test message'

# Check that the message is not present in the logs before the operation but is present after it 
expect { operation }.to log message: 'Test message',
                            user_id: 123456

# Expect a certain log level
log_output_is_expected.to include_log_message(message: 'Test message').at_level(:info)
expect { operation }.to log(message: 'Test message').at_level(:info)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version,
update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag
for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/zormandi/logcraft. This project is intended
to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the
[code of conduct](https://github.com/zormandi/logcraft/blob/master/CODE_OF_CONDUCT.md).

## Disclaimer

Logcraft is highly opinionated software and does in no way aim or claim to be useful for everyone.
Use at your own discretion.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Logcraft project's codebases, issue trackers, chat rooms and mailing lists is expected
to follow the [code of conduct](https://github.com/zormandi/logcraft/blob/master/CODE_OF_CONDUCT.md).
