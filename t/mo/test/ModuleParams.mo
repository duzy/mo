say('1..5');

if +@ARGS == 4
  say('ok - @ARGS has 4 elements');
  if @ARGS[0] eq 'param-1'
    say('ok - @ARGS[0] = param-1');
  end
  if @ARGS[1] eq 'param-2'
    say('ok - @ARGS[1] = param-2');
  end
  if @ARGS[2] eq 'param-3'
    say('ok - @ARGS[2] = param-3');
  end
  if @ARGS[3] == 123
    say('ok - @ARGS[3] = 123');
  end
end
