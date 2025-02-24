require "test_helper"

module Witsec
  class SchemaTest < ActiveSupport::TestCase
    describe ".define" do
      it "builds a new schema instance" do
        schema = Witsec::Schema.define(version: 2025_01_15_142512) do
          exclude_table "action_text_rich_texts"

          anonymize_table "addresses" do |t|
            t.column "street", using: -> { Faker::Address.street_address }
            t.column "zip_code", using: -> { Faker::Number.number(digits: 4) }
            t.column "city", using: -> { Faker::Address.city }
          end
        end

        assert_equal ["addresses"], schema.anonymized_tables.map(&:name)
        assert_equal ["action_text_rich_texts"], schema.excluded_tables
      end

      it "can take a hard coded default value" do
        schema = Witsec::Schema.define(version: 2025_01_15_142512) do
          anonymize_table "addresses" do |t|
            t.column "city", using: "FakeCity"
          end
        end

        assert_equal ["city", "FakeCity"], schema.anonymized_tables.first.columns.last
      end
    end
  end

  describe "#include_table" do
    it "adds a table to the anonymized_tables list without any anonymizers" do
      schema = Witsec::Schema.new(version: 2025_01_15_142512)

      schema.include_table("addresses")

      table = schema.anonymized_tables.first
      assert_equal "addresses", table.name
      assert_empty table.columns
    end
  end

  describe "#anonymizes?" do
    it "is true for tables in the list of anonymized_tables" do
      schema = Witsec::Schema.define(version: 2025_01_15_142512) do
        anonymize_table "addresses" do |t|
          t.column "street", using: -> { Faker::Address.street_address }
        end
      end

      assert_equal true, schema.anonymizes?("addresses")
    end

    it "is false for tables not in the list of anonymized_tables" do
      schema = Witsec::Schema.define(version: 2025_01_15_142512) do
        anonymize_table "addresses" do |t|
          t.column "street", using: -> { Faker::Address.street_address }
        end
      end

      assert_equal false, schema.anonymizes?("users")
    end
  end

  describe "#table_names" do
    it "returns a list of all table names in the schema sorted alphabetically" do
      schema = Witsec::Schema.define(version: 2025_01_15_142512) do
        anonymize_table "addresses" do |t|
          t.column "street", using: -> { Faker::Address.street_address }
        end
        exclude_table "very_secret_things"
        include_table "users"
      end

      assert_equal ["addresses", "users", "very_secret_things"], schema.table_names
    end
  end
end
