say("1..22")

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
        say("fail\t\t- .NAME eq 'test' : " ~ .NAME)
      end

      if $_.name eq 't/mo/test'
        say("ok\t\t- $_.name eq 't/mo/test'")
      else
        say("fail\t\t- $_.name eq 't/mo/test' : "~$_.name)
      end
  }

with ->'t/mo'['test'] do
  {
      if .EXISTS
        say("ok\t\t- test exists")
      else
        say("fail\t\t- test not exists: " ~ .EXISTS)
      end

      if .NAME eq 'test'
        say("ok\t\t- .NAME eq 'test'")
      else
        say("fail\t\t- .NAME eq 'test' : " ~ .NAME)
      end

      if $_.name eq 't/mo/test'
        say("ok\t\t- $_.name eq 't/mo/test'")
      else
        say("fail\t\t- $_.name eq 't/mo/test' : "~$_.name)
      end
  }

for ->'.'['test/many/1.txt', "test/many/2.txt"] do
  {
      if $_.name eq './test/many/1.txt'
        say("ok\t\t- $_.name eq './test/many/1.txt'")
      elsif $_.name eq './test/many/2.txt'
        say("ok\t\t- $_.name eq './test/many/2.txt'")
      else
        say("fail\t\t- $_.name : "~$_.name)
      end

      if .NAME eq '1.txt'
        say("ok\t\t- .NAME eq 1.txt")
      elsif .NAME eq '2.txt'
        say("ok\t\t- .NAME eq 2.txt")
      else
        say("fail\t\t- unexpected: " ~ .NAME)
      end
  }

for ->'test/many'['1.txt', "2.txt"] do
  {
      if $_.name eq 'test/many/1.txt'
        say("ok\t\t- $_.name eq 'test/many/1.txt'")
      elsif $_.name eq 'test/many/2.txt'
        say("ok\t\t- $_.name eq 'test/many/2.txt'")
      else
        say("fail\t\t- $_.name : "~$_.name)
      end

      if .NAME eq '1.txt'
        say("ok\t\t- .NAME eq 1.txt")
      elsif .NAME eq '2.txt'
        say("ok\t\t- .NAME eq 2.txt")
      else
        say("fail\t\t- unexpected: " ~ .NAME)
      end
  }

var $a = ->'.'
  [
   "test/many/1.txt",
   "test/many/2.txt",
  ]
  {
  say('~~~~')
      if $_.name eq './test/many/1.txt'
        say("ok\t\t- $_.name eq './test/many/1.txt'")
      elsif $_.name eq './test/many/2.txt'
        say("ok\t\t- $_.name eq './test/many/2.txt'")
      else
        say("fail\t\t- $_.name : "~$_.name)
      end

      if .NAME eq '1.txt'
        say("ok\t\t- .NAME eq 1.txt")
      elsif .NAME eq '2.txt'
        say("ok\t\t- .NAME eq 2.txt")
      else
        say("fail\t\t- unexpected .NAME: " ~ .NAME)
      end

      1
  }

if +$a == 2
    say('ok - +$a == 2')
else
    say('fail - +$a == 2')
end

$a = ->"test/many"
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

      1
  }

if +$a == 2
    say('ok - +$a == 2')
else
    say('fail - +$a == 2')
end
