require_relative 'db_connection'
require 'active_support/inflector'

# NB: the attr_accessor we wrote in phase 0 is NOT used in the rest
# of this project. It was only a warm up.

class SQLObject
  def self.columns
    return @columns if @columns
    col ||= DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    @columns = col.first.map!(&:to_sym)
  end

  def self.finalize!
    columns.each do |col|
      define_method(col) { attributes[col]}
      define_method("#{col}=") do |val|
        attributes[col] = val
      end
    end
  end

  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    @table_name || self.to_s.tableize
  end

  def self.all
    results = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        #{table_name}
    SQL
    parse_all(results)
  end

  def self.parse_all(results)
    results.map do |row|
      self.new(row)
    end
  end

  def self.find(id)
    result = DBConnection.execute(<<-SQL)
      SELECT
        *
      FROM
        '#{table_name}'
      WHERE
        id = '#{id}'
    SQL
    return nil if result.empty?
    self.new(result.first)
  end

  def initialize(params = {})
    params.each do |key,val|
      unless self.class.columns.include?(key.to_sym)
        raise "unknown attribute '#{key}'"
      end
      self.send("#{key.to_sym}=",val)
    end

  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|col| self.send(col)}
  end

  def insert
    col_names = self.class.columns.drop(1)
    question_marks = ["?"]*col_names.length
      DBConnection.execute(<<-SQL, *attribute_values.drop(1))
      INSERT INTO
        #{self.class.table_name} (#{col_names.join(',')})
      values
        (#{question_marks.join(",")})
      SQL
    self.send("id=",DBConnection.last_insert_row_id)

  end

  def update
    col_names = self.class.columns.drop(1)
    column_names = col_names.map {|col| "#{col} = ?"}.join(",")
    DBConnection.execute(<<-SQL, *attribute_values.drop(1), self.id)
      UPDATE
        #{self.class.table_name}
      SET
        #{column_names}
      WHERE
        id = ?
      SQL
  end

  def save
    self.id.nil? ? insert : update
  end
end
