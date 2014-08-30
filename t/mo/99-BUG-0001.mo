say("1..2")

->"test/many"
  [
   "1.txt",
   "2.txt",
  ]
  {
      if .NAME eq '1.txt'
        say("ok\t\t- .NAME eq 1.txt")
      elsif .NAME eq '2.txt'
        say("ok\t\t- .NAME eq 2.txt")
      else
        say("fail\t\t- unexpected .NAME: " ~ .NAME)
      end

      0
  }
