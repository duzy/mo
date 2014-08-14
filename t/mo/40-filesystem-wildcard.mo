for ->[ "test/many/*.txt" ] do
  {
      if .name eq '1.txt'
        say("ok\t\t- 1.txt")
      elsif .name eq '2.txt'
        say("ok\t\t- 2.txt")
      elsif .name eq '3.txt'
        say("ok\t\t- 3.txt")
      else
        say("fail\t\t- unexpected: " ~ .name)
      end
  }
