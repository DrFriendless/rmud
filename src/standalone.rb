require_relative './repl.rb'
require_relative './world.rb'
require 'psych'

w = World.new
w.load_lib
w.persist
Repl.new.run