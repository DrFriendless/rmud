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

  def save_player(data)
    # TODO
    p "save_player #{data}"
  end

  def check_password(username, password)
    players = @client[:players]
    us = []
    # there must be something better than this.
    players.find({:username => username}).each { |row| us.push(row) }
    if us.length > 0
      if us[0][:password] == password
        return us[0]
      else
        return ()
      end
    else
      rec = { :username => username, :password => password, :location => "lib/Room/library" }
      players.insert_one(rec)
      rec
    end
  end

  def load()
    rows = []
    @client[:world].find().each { |r|
      rows.push(r)
    }
    rows
  end
end