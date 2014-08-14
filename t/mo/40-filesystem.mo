for ->['test'] do
  {
    say(.name)
    say(.path)
  }

for ->['test/many/1.txt', "test/many/2.txt"] do
  {
      if .name eq '1.txt'
        say("ok\t\t- 1.txt")
      elsif .name eq '2.txt'
        say("ok\t\t- 2.txt")
      else
        say("fail\t\t- unexpected: " ~ .name)
      end
  }

->[
   "test/many/1.txt",
   "test/many/2.txt",
  ]
  {
      if .name eq '1.txt'
        say("ok\t\t- 1.txt")
      elsif .name eq '2.txt'
        say("ok\t\t- 2.txt")
      else
        say("fail\t\t- unexpected: " ~ .name)
      end

      0
  }
