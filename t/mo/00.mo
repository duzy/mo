say('glob: * = '~join(',',glob('*')));
say('glob: .* = '~join(',',glob('.*')));
say('glob: t/mo/0?.mo = '~join(',',glob('t/mo/0?.mo')));
say('glob: t/mo/0*.mo = '~join(',',glob('t/mo/0*.mo')));
say('glob: t/mo/t*t/M*.mo = '~join(',',glob('t/mo/t*t/M*.mo')));
say('glob: t/mo/0[12345]*.mo = '~join(',',glob('t/mo/0[12345]*.mo')));
say('glob: t/mo/0[1-9]*.mo = '~join(',',glob('t/mo/0[1-9]*.mo')));
say('glob: t/mo/{00,01,02,03,04,05,06,07,08,09}.mo = '~join(',',glob('t/mo/{00,01,02,03,04,05,06,07,08,09}.mo')));
