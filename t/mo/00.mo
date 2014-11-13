say('glob: * = '~glob('*'));
say('glob: t/mo/0* = '~glob('t/mo/0*'));
say('glob: t/mo/t*t/M*.mo = '~glob('t/mo/t*t/M*.mo'));
say('glob: t/mo/0[0-9]* = '~glob('t/mo/0[0-9]*'));
say('glob: t/mo/{00,01,02,03,04,05,06,07,08,09}.mo = '~glob('t/mo/{00,01,02,03,04,05,06,07,08,09}.mo'));
