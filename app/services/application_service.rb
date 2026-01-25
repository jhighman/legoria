# frozen_string_literal: true

class ApplicationService
  extend Dry::Initializer
  include Dry::Monads[:result, :do]

  def self.call(...)
    new(...).call
  end
end
