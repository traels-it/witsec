require "test_helper"

module Witsec
  class AliasTest < ActiveSupport::TestCase
    it "anonymizes a list of rows" do
      schema = Witsec::Schema.define(version: 2025_01_15_142512) do
        anonymize_table "addresses" do |t|
          t.column "street", using: -> { Faker::Address.street_address }
          t.column "zip_code", using: -> { Faker::Number.number(digits: 4) }
          t.column "city", using: -> { Faker::Address.city }
        end
      end
      columns = ["id", "street", "zip_code", "city", "legal_entity_type", "legal_entity_id", "created_at", "updated_at", "country_code"]
      row = [905321388, "Hejrupshøjhedesvej 18", "8400", "Ebeltoft", "LegalEntities::Company", 905321388, DateTime.parse("2025-01-30 12:35:30.93788 UTC"), DateTime.parse("2025-01-30 12:35:30.93788 UTC"), 0]

      result = Witsec::Alias.new("addresses", columns:, schema:).anonymize([row])

      anonymized_street = result[0][1]
      anonymized_zip_code = result[0][2]
      anonymized_city = result[0][3]

      assert_not_equal row[1], anonymized_street
      assert_not_equal row[2], anonymized_zip_code
      assert_not_equal row[3], anonymized_city
    end

    it "does not touch rows without defined masks" do
      schema = Witsec::Schema.define(version: 2025_01_15_142512) do
        anonymize_table "addresses" do |t|
          t.column "street", using: -> { Faker::Address.street_address }
          t.column "zip_code", using: -> { Faker::Number.number(digits: 4) }
          t.column "city", using: -> { Faker::Address.city }
        end
      end
      columns = ["id", "street", "zip_code", "city", "legal_entity_type", "legal_entity_id", "created_at", "updated_at", "country_code"]
      row = [905321388, "Hejrupshøjhedesvej 18", "8400", "Ebeltoft", "LegalEntities::Company", 905321388, DateTime.parse("2025-01-30 12:35:30.93788 UTC"), DateTime.parse("2025-01-30 12:35:30.93788 UTC"), 0]
      unanonymized_data = [905321388, "LegalEntities::Company", 905321388, DateTime.parse("2025-01-30 12:35:30.93788 UTC"), DateTime.parse("2025-01-30 12:35:30.93788 UTC"), 0]

      anonymized_row = Witsec::Alias.new("addresses", columns:, schema:).anonymize([row]).first

      result = [anonymized_row.first] + anonymized_row.slice(4..)

      assert_equal unanonymized_data, result
    end
  end
end
