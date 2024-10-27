module ExtendActiveRecord
  def last(*args)
    if to_sql.include?("DISTINCT ON")
      limit = args.first
      result = unscoped.from("(#{to_sql}) AS subq").select("subq.*").order("subq.index DESC").limit(limit)

      limit ? result.reverse : result.first
    else
      super(*args)
    end
  end

  def count(*args)
    if to_sql.include?("DISTINCT ON")
      # print stack trace
      puts "stack trace in count:"
      puts caller.join("\n")
      before_sql = to_sql
      puts "before_sql: #{before_sql}"
      unscoped_sql = unscoped.from("(#{reorder(nil).to_sql}) AS subq").select("count(*)").to_sql
      puts "unsoped_sql: #{unscoped_sql}"
      unscoped.from("(#{reorder(nil).to_sql}) AS subq").select("count(*)").to_a.first["count"].to_i
    else
      super(*args)
    end
  end
end

ActiveRecord::Relation.prepend(ExtendActiveRecord)
