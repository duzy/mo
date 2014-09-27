for -><t/mo>[ "test/many/*.txt" ] do
  {
      if .NAME eq '1.txt'
        say("ok\t\t- 1.txt")
      elsif .NAME eq '2.txt'
        say("ok\t\t- 2.txt")
      elsif .NAME eq '3.txt'
        say("ok\t\t- 3.txt")
      else
        say("fail\t\t- unexpected .NAME: " ~ .NAME)
      end
  }
