namespace :witsec do
  desc "Anonymizes the app's primary database"
  task anonymize: :environment do
    Witsec::Anonymizer.new.anonymize
  end

  namespace :schema do
    desc "Verify that the Witsec schema defines an anonymization for each table"
    task :verify_tables, [:raise_error] => :environment do |_t, args|
      args.with_defaults(raise_error: false)

      anonymizer = Witsec::Anonymizer.new

      if anonymizer.schema.table_names != ActiveRecord::Base.connection.tables.sort
        missing_tables = ActiveRecord::Base.connection.tables - anonymizer.schema.table_names
        extra_tables = anonymizer.schema.table_names - ActiveRecord::Base.connection.tables

        messages = ["Witsec schema contains errors"]

        messages << "Missing tables: #{missing_tables.join(", ")}" if missing_tables.any?
        messages << "Extra tables: #{extra_tables.join(", ")}" if extra_tables.any?

        return unless messages.any?

        if args[:raise_error]
          raise Witsec::TableMismatchError, messages.join("\n")
        else
          abort messages.join("\n")
        end
      end
    end

    desc "Verify the Witsec schema version matches the version of the latest run migration"
    task :verify_version, [:raise_error] => :environment do |_t, args|
      args.with_defaults(raise_error: false)

      app_schema_version = ActiveRecord::Base.connection.schema_version
      witsec_schema_version = Witsec::Anonymizer.new.schema.version
      message = "Witsec schema version (#{witsec_schema_version}) does not match app's schema version (#{app_schema_version})"

      if app_schema_version != witsec_schema_version
        if args[:raise_error]
          raise Witsec::VersionError, message
        else
          abort message
        end
      end
    end

    desc "Runs all other Witsec verifications"
    task verify: :environment do
      error_messages = []
      begin
        Rake::Task["witsec:schema:verify_tables"].invoke(true)
      rescue Witsec::TableMismatchError => error
        error_messages << error.message
      end
      begin
        Rake::Task["witsec:schema:verify_version"].invoke(true)
      rescue Witsec::VersionError => error
        error_messages << error.message
      end

      if error_messages.any?
        abort error_messages.join("\n")
      else
        puts "Witsec schema is all good 🎉"
      end
    end
  end
end
