require_relative 'db_connection'
require_relative '01_sql_object'

module Searchable
  def where(params)
    col_names = params.keys.map {|col| "#{col} = ?"}.join(" AND ")
    values = params.values
    results = DBConnection.execute(<<-SQL, *values)
      SELECT
        *
      FROM
        #{table_name}
      where
        #{col_names}
    SQL
    parse_all(results)
  end
end

class SQLObject
  extend Searchable
  # Mixin Searchable here...
end
