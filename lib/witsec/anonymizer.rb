module Witsec
  class Anonymizer
    BATCH_SIZE = 1000

    def initialize
      @schema = instance_eval(File.read("config/witsec/schema.rb"))

      check_input_and_output_are_different
    end

    attr_reader :schema

    # TODO: Make silence configurable
    def anonymize
      time = Benchmark.measure do
        ActiveRecord::Base.logger.silence do
          clear_output_database

          ActiveRecord::Base.connection.tables.each do |table_name|
            if schema.anonymizes?(table_name)
              # A performance improvement could probably be found here, if we just passed along included tables (as in tables, where no rows are anonymized) without querying etc.

              input_connection = input_connection_pool.lease_connection
              record_rows = input_connection.execute("SELECT * FROM #{table_name}").to_a
              columns = record_rows&.first&.keys
              rows = record_rows.map(&:values)
              puts "Anonymizing #{table_name} (#{rows.size} rows)"
              input_connection_pool.release_connection

              anonymized_rows = Witsec::Alias.new(table_name, columns:, schema:).anonymize(rows)
              output_connection = output_connection_pool.lease_connection
              # If referential integrity is not disabled, you have to create all rows in the correct order
              output_connection.disable_referential_integrity do
                # Use insert for performance
                row_batches = anonymized_rows.in_groups_of(BATCH_SIZE, false)
                total = 0
                row_batches.each_with_index do |batch, index|
                  print "Anonymizing up to row #{total + batch.size} of #{rows.size}\r"
                  total += batch.size
                  values = batch.map do |row|
                    "(#{row.map { |value| ActiveRecord::Base.connection.quote(value) }.join(", ")})"
                  end.join(", ")

                  output_connection.execute(
                    "INSERT INTO #{table_name} (#{columns.join(", ")}) VALUES #{values}"
                  )
                end
              end

              output_connection_pool.release_connection
            else
              puts "Skipping #{table_name}"
              next
            end
          end
        end
      end
      puts "Anonymized all in #{time.real} seconds"
    end

    def clear_output_database
      puts "Clearing output database"

      ActiveRecord::Base.logger.silence do
        connection = output_connection_pool.lease_connection

        connection.disable_referential_integrity do
          connection.tables.each do |table_name|
            connection.execute("TRUNCATE TABLE #{table_name} CASCADE")
          end
        end

        output_connection_pool.release_connection
      end
    end

    private

    def check_input_and_output_are_different
      if input_connection_pool.lease_connection.current_database == output_connection_pool.lease_connection.current_database
        raise Witsec::InputAndOutputDatabasesAreTheSame, "You've probably forgotten to setup the output database. It must be named anonymized."
      end
    end

    def input_database_configuration
      Rails.configuration.database_configuration[Rails.env]["primary"]
    end

    def input_connection_pool
      ActiveRecord::Base.establish_connection(input_database_configuration)
    end

    def output_database_configuration
      Rails.configuration.database_configuration[Rails.env]["anonymized"]
    end

    def output_connection_pool
      ActiveRecord::Base.establish_connection(output_database_configuration)
    end
  end
end
