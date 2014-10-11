say('1..7');

var $Test = 100;

load {
  if !isnull(@_) && +@_ == 2
    if @_[0] eq 'param-0'
      say('ok - 1. @_[0] = param-0')
    end
    if @_[1] == 1
      say('ok - 2. @_[1] = 1')
    end
  end
  if !isnull(%_) && +%_ == 2
    if %_{'s'} eq 'param-1'
      say('ok - 3. %_{"s"} = param-1')
    end
    if %_{'n'} == 123
      say('ok - 4. %_{"n"} = 123')
    end
  end
  $Test = 'test';
  say('ok - 5. load: $Test = '~$Test);
}

def Check() {
    if $Test eq 'test' {
        say('ok - 6. $Test = '~$Test);
    } else {
        say('xx - 6. $Test = '~$Test);
    }
}
