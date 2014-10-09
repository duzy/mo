say('1..2');

var $v1 =   <'t/mo/test/text.txt'>;
var $v2 = -><'t/mo/test/text.txt'>;
say($v1.get('PATH'));
say($v2.get('PATH'));

with -><'t/mo/test'>['text.txt'] do
  {
      if .EXISTS
          say("ok\t\t- found "~..)
          var $h = open(.PATH, 'r')
          var $s = $h.readline
          if $s eq "text\n"
              say("ok\t\t- text")
          else
              say("xx\t\t- wrong line: "~$s)
          end
          $h.close
      else
          say("xx\t\t- missing text.txt")
      end
  }
