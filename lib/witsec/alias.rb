module Witsec
  class Alias
    def initialize(table_name, columns:, schema:)
      @table_name = table_name.to_s
      @columns = columns
      @schema = schema
    end

    def anonymize(rows)
      rows.map do |row|
        columns.each_with_index.map do |column, index|
          anonymized_column, mask = table.columns.find { |name, _mask| name == column.to_s }

          if anonymized_column.present?
            mask.respond_to?(:call) ? mask.call : mask
          else
            row[index]
          end
        end
      end
    end

    private

    attr_reader :table_name, :columns, :schema

    def table
      @table ||= schema.anonymized_tables.find { _1.name == table_name }
    end
  end
end
