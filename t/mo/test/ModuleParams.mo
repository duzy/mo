say('1..6');

if +@ARGS == 5
  say('ok - @ARGS has 5 elements');
  if 0 < index(@ARGS[0], '/t/mo/test/ModuleParams.mo')
    say('ok - @ARGS[0] = .../t/mo/test/ModuleParams.mo');
  else
    say('xx - @ARGS[0] = '~@ARGS[0]);
  end
  if @ARGS[1] eq 'param-1'
    say('ok - @ARGS[1] = param-1');
  end
  if @ARGS[2] eq 'param-2'
    say('ok - @ARGS[2] = param-2');
  end
  if @ARGS[3] eq 'param-3'
    say('ok - @ARGS[3] = param-3');
  end
  if @ARGS[4] == 123
    say('ok - @ARGS[4] = 123');
  end
end
