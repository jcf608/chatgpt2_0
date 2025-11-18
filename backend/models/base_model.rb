# BaseModel - Base class for all Sequel models
# Provides common functionality: timestamps, validations, error handling

class BaseModel < Sequel::Model
  # Plugin for automatic timestamps
  plugin :timestamps, update_on_create: true

  # Common validations
  def validate
    super
    # Add common validations here if needed
  end

  # Common error handling
  def self.find_or_raise(id)
    record = self[id]
    raise StandardError, "#{self.name} not found with id: #{id}" unless record
    record
  end

  # Common query helpers
  def self.recent(limit = 10)
    order(Sequel.desc(:created_at)).limit(limit)
  end

  def self.created_after(date)
    where { created_at > date }
  end

  def self.created_before(date)
    where { created_at < date }
  end
end

