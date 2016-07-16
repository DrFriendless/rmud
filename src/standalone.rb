require_relative './repl.rb'
require_relative './world.rb'
require_relative './database.rb'
require 'psych'

w = World.new
w.load_lib
db = Database.new
db.save(w.persist)
puts "LOADING"
puts db.load
Repl.new.run