class Item < Thing
    def after_properties_set
      super
      verb(["examine", :it]) { |response, command, match|
        response.message = long
        response.handled = true
      }
      verb(["get", :it]) { |response,command,match|
        if @location == command.body.location
          if carriable?
            move_to(command.body)
            command.body.location.publish_to_room(TakeEffect.new(command.body, self))
          else
            response.message = "You can't take that."
          end
          response.handled = true
        end
      }
      alias_verb(["take", :it], ["get", :it])
      verb(["drop", :it]) { |response,command,match|
        if @location == command.body
          if command.body.wearing?(self)
            command.body.remove(self)
          end
          if command.body.wearing?(self)
            response.message = "You can't take that off."
          else
            move_to(command.body.location)
            command.body.location.publish_to_room(DropEffect.new(command.body, self))
          end
        else
          response.message = "You don't have that."
        end
        response.handled = true
      }
    end

    def carriable?()
      true
    end
end