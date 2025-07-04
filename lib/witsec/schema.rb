module Witsec
  class Schema
    class << self
      def define(version, &block)
        new(version).define(&block)
      end
    end

    def initialize(version)
      @version = version
      @anonymized_tables = []
      @excluded_tables = []
    end

    attr_reader :version, :anonymized_tables, :excluded_tables

    def define(&block)
      instance_eval(&block)

      self
    end

    def exclude_table(name)
      excluded_tables << name
    end

    def include_table(name)
      anonymized_tables << Table.new(name)
    end

    def anonymize_table(name, &block)
      anonymized_tables << Table.new(name).define do
        instance_eval(&block)
      end
    end

    def anonymizes?(table_name)
      anonymized_table_names.include?(table_name.to_s)
    end

    def table_names
      (anonymized_table_names + excluded_tables).sort
    end

    private

    def anonymized_table_names
      anonymized_tables.map(&:name)
    end
  end

  class Table
    def initialize(name)
      @name = name
      @columns = []
    end

    attr_reader :name, :columns

    def define(&block)
      instance_eval(&block)

      self
    end

    def column(column_name, using: nil)
      columns << [column_name, using]
    end
  end

  TableMismatchError = Class.new(StandardError)
  VersionError = Class.new(StandardError)
end
