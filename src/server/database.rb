require 'mongo'

class Database
  def initialize
    Mongo::Logger.logger.level = ::Logger::INFO
    @client = Mongo::Client.new('mongodb://127.0.0.1:27017/rmud')
  end

  def obj_to_strs(hash)
    result = {}
    hash.each { |k,v| result["#{k}"] = v}
    result
  end

  def mongoify(data)
    result = {}
    data.each { |k,v|
      v[:_id] = k
      result[k] = obj_to_strs(v)
    }
    result
  end

  def save_player(name, data)
    p "SAVE name #{name} data #{data}"
    players = @client[:players]
    players.update_one({:_id => name}, {"$set" => data})
  end

  def retrieve_player(name)
    players = @client[:players]
    ps = players.find({:_id => name}).to_a
    ps.length > 0 ? ps[0] : nil
  end

  def save(data)
    begin
      data = mongoify(data)
      with_ids = data.values
      w = @client[:world]
      ids = w.find.projection("_id" => 1).distinct("_id")
      to_update = with_ids.select { |item| ids.include? item["_id"] }
      updates = []
      to_update.each { |u|
        id = u["_id"]
        diff = data[id].to_a - w.find("_id" => id).first.to_a
        unless diff.empty?
          diff = Hash[*diff.flatten(1)]
          diff["_id"] = id
          updates.push(diff)
        end
      }
      to_insert = with_ids.select { |item| !ids.include? item["_id"] }
      to_delete = ids.select { |item| !data.keys.include? item }
      to_delete.each { |k| w.delete_one("_id" => k) }
      updates.each { |r| w.find(:_id => r["_id"]).find_one_and_replace({ "$set" => r }) }
    rescue Mongo::Error::BulkWriteError
      err = $!
      puts "DELETE #{err.result}"
    end
    begin
      w.insert_many(to_insert)
    rescue Mongo::Error::BulkWriteError
      err = $!
      puts "INSERT 2 #{err.result}"
    end
  end

  def check_password(username, password)
    players = @client[:players]
    us = []
    # there must be something better than this.
    players.find({:username => username}).each { |row| us.push(row) }
    if us.length > 0
      p us[0]
      if us[0][:password] == password
        return us[0]
      else
        return nil
      end
    else
      rec = { :username => username, :password => password, :location => "lib/Room/library", :_id => username, :gp => 0, :xp => 0 }
      players.insert_one(rec)
      rec
    end
  end

  def load
    rows = []
    @client[:world].find().each { |r| rows.push(r) }
    rows
  end
end