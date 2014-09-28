say('1..2')
with -><'t/mo/test'>['text.txt'] do
  {
      if .EXISTS
          say("ok\t\t- found "~..)
          var $h = open(.PATH, 'r')
          var $s = $h.readline
          if $s eq "text\n"
              say("ok\t\t- text")
          else
              say("fail\t\t- wrong line: "~$s)
          end
          $h.close
      else
          say("fail\t\t- missing text.txt")
      end
  }
