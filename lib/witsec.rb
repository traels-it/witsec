require "witsec/version"
require "witsec/railtie"
require "witsec/alias"
require "witsec/anonymizer"
require "witsec/schema"

module Witsec
  class InputAndOutputDatabasesAreTheSame < StandardError
  end
end
