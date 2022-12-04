class ApplicationService
  include ActiveModel::Model
  attr_reader :result

  def self.call(...)
    new(...).call
  end

  def initialize(...)
    nil
  end

  def call
    validate_call
    perform if success?
    self
  end

  def success?
    errors.none?
  end

  private

  def perform
    nil
  end

  def validate_call
  end
end
