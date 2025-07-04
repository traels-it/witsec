require "witsec/version"
require "witsec/railtie"
require "witsec/alias"
require "witsec/anonymizer"
require "witsec/schema"
require "dry-configurable"

module Witsec
  extend Dry::Configurable

  setting :input do
    setting :adapter, default: :postgres, constructor: proc { |value| (value.to_sym == :postgresql) ? :postgres : value }
    setting :host
    setting :database, default: :primary
    setting :user
    setting :password
  end

  setting :output do
    setting :adapter, default: :postgres, constructor: proc { |value| (value.to_sym == :postgresql) ? :postgres : value }
    setting :host
    setting :database, default: :anonymized
    setting :user
    setting :password
  end

  class InputAndOutputDatabasesAreTheSame < StandardError
  end
end
