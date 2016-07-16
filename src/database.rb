require 'mongo'

class Database
  def initialize()
    @client = Mongo::Client.new('mongodb://127.0.0.1:27017/rmud')
  end

  def mongoify(data)
    data.each { |k,v| v[:_id] = k }
    data.values
  end

  def save(data)
    begin
      with_ids = mongoify(data)
      w = @client[:world]
      ids = w.find.projection(:_id => 1).distinct(:_id)
      to_update = with_ids.select { |item| ids.include? item[:_id] }
      to_insert = with_ids.select { |item| !ids.include? item[:_id] }
      to_delete = ids.select { |item| !data.keys.include? item }
      to_delete.each { |k| w.delete_one(:_id => k) }
      to_update.each { |r| w.delete_one(:_id => r[:_id]) }
    rescue Mongo::Error::BulkWriteError
      err = $!
      puts "DELETE #{err.result}"
    end
    begin
      w.insert_many(to_update)
    rescue Mongo::Error::BulkWriteError
      err = $!
      puts "INSERT 1 #{err.result}"
    end
    begin
      w.insert_many(to_insert)
    rescue Mongo::Error::BulkWriteError
      err = $!
      puts "INSERT 2 #{err.result}"
    end
  end

  def load()
    @client[:world].find()
  end
end