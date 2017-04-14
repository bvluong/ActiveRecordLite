require_relative '02_searchable'
require 'active_support/inflector'

# Phase IIIa
class AssocOptions
  attr_accessor(
    :foreign_key,
    :class_name,
    :primary_key
  )

  def model_class
    self.class_name.constantize
  end

  def table_name
    "#{self.class_name.camelcase.underscore}s"
  end
end

class BelongsToOptions < AssocOptions
  def initialize(name, options = {})
    @primary_key = (options[:primary_key] || :id)
    @foreign_key = (options[:foreign_key] || "#{name}_id".to_sym)
    @class_name = (options[:class_name] || name.to_s.camelcase)
  end
end

class HasManyOptions < AssocOptions
  def initialize(name, self_class_name, options = {})
    p self_class_name
    @primary_key = (options[:primary_key] || :id)
    @foreign_key = (options[:foreign_key] || "#{self_class_name.to_s.underscore}_id".to_sym)
    @class_name = (options[:class_name] || name.to_s.singularize.camelcase)
  end
end

module Associatable
  # Phase IIIb
  def belongs_to(name, options = {})
    options = BelongsToOptions.new(name, options)
    # define_method(name) do
    #   foreign_key_id = self.send(options.foreign_key)
    #   return nil if foreign_key_id.nil?
    #   results = DBConnection.execute(<<-SQL)
    #     SELECT
    #       *
    #     FROM
    #       #{options.class_name.constantize.table_name}
    #     WHERE
    #       #{options.primary_key} = #{self.send(options.foreign_key)}
    #   SQL
    #   options.class_name.constantize.new(results.first)
    # end

    define_method(name) do
      foreign_key_id = self.send(options.foreign_key)
      target_model_class = options.class_name.constantize
      target_model_class.where(options.primary_key => foreign_key_id).first
    end

  end

  def has_many(name, options = {})
    options = HasManyOptions.new(name, options)

    define_method(name) do
      target_model_class = options.class_name.constantize
      target_model_class.where( options.foreign_key => self.send(options.primary_key))
    end

  end

  def assoc_options

    # Wait to implement this in Phase IVa. Modify `belongs_to`, too.
  end
end

class SQLObject
  extend Associatable
  # Mixin Associatable here...
end
