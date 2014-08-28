with ->'t/mo/test' do
  {
      if .EXISTS
        say("ok\t\t- test exists")
      else
        say("fail\t\t- test not exists: " ~ .EXISTS)
      end

      if .NAME eq 'test'
        say("ok\t\t- .NAME eq 'test'")
      else
        say("fail\t\t- .NAME eq 'test': " ~ .NAME)
      end
  }

with ->'t/mo'['test'] do
  {
    say(.NAME)
    say(.PATH)
  }

for ->'.'['test/many/1.txt', "test/many/2.txt"] do
  {
      if .NAME eq '1.txt'
        say("ok\t\t- 1.txt")
      elsif .NAME eq '2.txt'
        say("ok\t\t- 2.txt")
      else
        say("fail\t\t- unexpected: " ~ .NAME)
      end
  }

for ->'test/many'['1.txt', "2.txt"] do
  {
      if .NAME eq '1.txt'
        say("ok\t\t- 1.txt")
      elsif .NAME eq '2.txt'
        say("ok\t\t- 2.txt")
      else
        say("fail\t\t- unexpected: " ~ .NAME)
      end
  }

->'.'
  [
   "test/many/1.txt",
   "test/many/2.txt",
  ]
  {
      if .NAME eq '1.txt'
        say("ok\t\t- 1.txt")
      elsif .NAME eq '2.txt'
        say("ok\t\t- 2.txt")
      else
        say("fail\t\t- unexpected: " ~ .NAME)
      end

      0
  }

->"test/many"
  [
   "1.txt",
   "2.txt",
  ]
  {
      if .NAME eq '1.txt'
        say("ok\t\t- 1.txt")
      elsif .NAME eq '2.txt'
        say("ok\t\t- 2.txt")
      else
        say("fail\t\t- unexpected: " ~ .NAME)
      end

      0
  }
