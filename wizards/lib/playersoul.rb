require_relative './soul.rb'

class PlayerSoul < Soul
  def initialize
    super
    verb(["look"]) { |response, command, match|
      response.handled = true
      lines = []
      # no reason this should happen, but if it does...
      if !command.body.location
        puts "Emergency moving #{@name} to the library."
        move_to_location("lib/Room/library")
      end
      if command.room.lit?
        lines.push(command.room.long)
        command.room.contents.each { |t|
          if t != command.body
            lines.push(t.long)
          end
        }
        response.message = lines.join("\n")
      else
        response.message = "It's dark and you can't see a thing."
      end
    }
    verb(["quit"]) { |response, command, match|
      response.handled = true
      response.quit = true
    }
    verb(["time"]) { |response, command, match|
      response.handled = true
      tod = world.time_of_day
      response.message =
          case tod
            when 0..39; "It's dawn."
            when 40..119; "It's morning."
            when 120..219; "It's the middle of the day."
            when 220..299; "It's afternoon."
            when 300..339; "It's dusk."
            when 340..419; "It's evening."
            when 420..519; "It's the middle of the night."
            when 520..599; "It's some time before dawn."
            else "Time has gone kind of wibbly-wobbly."
          end
    }
    verb(["inventory"]) { |response, command, match|
      response.handled = true
      lines = command.body.contents.map { |c|
        s = c.short
        if s && command.body.wearing?(c); s += " (#{c.worn_adjective})" end
        s
      }.select(&:itself)
      if lines.size == 0; lines.push("You don't have anything else.") end
      lines = ["You have #{command.body.gp} gold pieces.",""] + lines
      response.message = lines.join("\n")
    }
    alias_verb(["i"], ["inventory"])
    verb(["verbs"]) { |response, command, match|
      response.handled = true
      lines = []
      lines.push("From the room:")
      command.body.location.verbs.each { |v|
        lines.push("    #{v.pattern}")
      }
      response.message = lines.join("\n")
    }
    verb(["void"]) { |response, command, match|
      command.body.move_to_location("lib/Room/lostandfound")
      response.handled = true
    }
    # called destruct rather than destroy in honour of Lars
    verb(["destruct", :plus]) { |response, command, match|
      thing = command.room.find(match[0].join(' ')) || command.body.find(match[0].join(' '))
      if thing
        thing.destroy
      else
        response.message = "Destroy what?"
      end
      response.handled = true
    }
  end
end