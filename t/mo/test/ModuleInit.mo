say('1..5');

var $Test;

init {
  if +@_ == 3
    if @_[0] eq 'param-1'
      say('ok - 1. @_[0] = param-1')
    end
    if @_[1] eq 'param-2'
      say('ok - 2. @_[1] = param-2')
    end
    if @_[2] == 123
      say('ok - 3. @_[2] = 123')
    end
  end
  $Test = 'test';
  say('ok - 4. init, '~$Test);
}
