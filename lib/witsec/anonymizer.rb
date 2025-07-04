require "sequel"

module Witsec
  class Anonymizer
    BATCH_SIZE = 1000

    def initialize(schema_path = "config/witsec/schema.rb")
      @schema = instance_eval(File.read(schema_path))

      check_input_and_output_are_different
    end

    attr_reader :schema

    def anonymize
      time = Benchmark.measure do
        clear_output_database

        input_database.tables.each do |table_name|
          next unless schema.anonymizes?(table_name)

          # A performance improvement could probably be found here, if we just passed along included tables (as in tables, where no rows are anonymized) without querying etc.
          record_rows = input_database[table_name].all
          columns = record_rows&.first&.keys
          rows = record_rows.map(&:values)
          puts "Anonymizing #{table_name} (#{rows.size} rows)"

          anonymized_rows = Witsec::Alias.new(table_name, columns:, schema:).anonymize(rows)

          row_batches = anonymized_rows.in_groups_of(BATCH_SIZE, false)
          total = 0
          row_batches.each_with_index do |batch, index|
            print "Anonymizing up to row #{total + batch.size} of #{rows.size}\r"
            total += batch.size

            disable_output_referential_integrity do
              output_database[table_name].import(columns, batch)
            end
          end
        end
      end
      puts "Anonymized all in #{time.real} seconds"
    end

    private

    def clear_output_database
      puts "Clearing output database"

      output_database.tables.each do |table_name|
        output_database.run("TRUNCATE TABLE #{table_name} CASCADE")
      end
    end

    def check_input_and_output_are_different
      return if defined?(Rails) && Rails.env.test?

      if Witsec.config.output == Witsec.config.input
        raise Witsec::InputAndOutputDatabasesAreTheSame
      end
    end

    def output_database
      @output_database ||= Sequel.connect(**Witsec.config.output.to_h)
    end

    def input_database
      @input_database ||= Sequel.connect(**Witsec.config.input.to_h)
    end

    def disable_output_referential_integrity(&block)
      case output_database.adapter_scheme
      when :postgres
        output_database.run(output_database.tables.collect { |name| "ALTER TABLE #{name} DISABLE TRIGGER ALL" }.join(";"))

        yield

        output_database.run(output_database.tables.collect { |name| "ALTER TABLE #{name} ENABLE TRIGGER ALL" }.join(";"))
      else
        raise "Cannot disable referential integrity for #{output_database.adapter_scheme}"
      end
    end
  end
end
