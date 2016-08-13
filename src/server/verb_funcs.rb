def tell(s)
  Proc.new do |response, command, match|
    command.body.tell(s)
    response.handled = true
  end
end

def goto(s, how=nil)
  Proc.new do |response, command, match|
    dest = local_dest(s)
    command.body.go_to(dest, how)
    response.handled = true
  end
end

def heal(n)
  Proc.new do |response, command, match|
    command.body.heal(n)
    response.handled = true
  end
end

def say(s)
  Proc.new do |response, command, match|
    command.body.quick_command("say " + s)
    response.handled = true
  end
end

def selfdestruct()
  Proc.new do |response, command, match|
    destroy
    response.handled = true
  end
end

def do(cmd)
  Proc.new do |response, command, match|
    command.body.quick_command(eval(cmd))
    response.handled = true
  end
end