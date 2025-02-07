# Witsec
When developing Rails applications you end up with a large difference between the size of the database used in development and the database in production. This makes it hard to gauge, how the performance is impacted as the amount of data grows.

You can try to generate a large set of data, but there is not guarantee, that the data you generate will produce the same performance issues as the real data would. Another approach is to download a database dump, but then you have real production data lying on your machine - including any sensitive data like SSNs or addresses.

This gem tries to avoid this by copying all data to a new database, anonymizing it all in the process. This new database can now be dumped and used in development.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "witsec"
# if you want a simple way to generate fake data
gem "faker"
```

And then execute:
```bash
$ bundle
```
Then create a new file at `config/witsec/schema.rb`. This path will become configurable in a later version.
Finally configure your database to create a database to store the anonymized data in:
```yaml
production:
  primary:
    <<: *default
    host: your_host_url
    database: you_app_name
  anonymized:
    <<: *default
    host: some_url_that_might_or_might_not_be_the_same_as_your_host_url
    database: anonymized # This must be called anonymized for now. It will become configurable in a later version. 
    migrations_paths: db/migrate
```

## Usage
Witsec uses a schema file to determine what to anonymize and how to do it.

```ruby
# config/witsec/schema.rb
Witsec::Schema.define(2025_01_15_142512) do
  anonymize_table "addresses" do |t|
    t.column "street", using: -> { Faker::Address.street_address }
    t.column "zip_code", using: -> { Faker::Address.zip_code }
    t.column "city", using: "New York"
  end

  include_table "animals"

  exclude_table "government_secrets"
end
```
`Witsec::Schema.define` requires an integer param. This should match the latest timestamp in your app's `db/schema.rb` and is used to ensure, that you have considered any changes introduced in database migrations. A warning is shown if a mismatch is detected, when you run the `bin/rails witsec:schema:verify` task. An error will be raised in a later version, when attempting to anonymize a database with a mismatch in versions.

There are three ways to anonymize a table:

#### `anonymize_table`
Takes the name of a table to be anonymized and a block, determining how each column should be masked. In the example above, [Faker](https://github.com/faker-ruby/faker) is used to provide a random address, but you can put whatever you want in the lambda or even provide a static value as is done on the city column.

Any column not mentioned in the block, will **not** be anonymized.

#### `include_table` 
Takes the name of a table to be copied in its entirety without any masking at all. Use this for tables without **any** sensitive data.

#### `exclude_table`
Takes the name of a table to be excluded. No data will be copied. If any other tables reference anything in an excluded table, you are probably going to have a bad time.

### Rake tasks
Witsec comes with some tasks for anonymizing the database and verifying that the schema is up to date.

#### `witsec:anonymize`
Anonymizes the app's primary database using the configuration defined in your schema.

#### `witsec:scheme:verify_tables`
Checks that the tables in your database are all mentioned in your Witsec schema. Useful as a step in your CI.

#### `witsec:scheme:verify_version`
Checks that your Witsec::Schema version matches the version of your latest run migration. Useful as a step in your CI.

#### `witsec:scheme:verify`
Runs all other verifications

## Contributing
Bug reports and pull requests are welcome on GitHub at https://github.com/traels-it/witsec.

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
