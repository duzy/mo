var $v = lang bash
-------------------
echo test
----------------end
say($v)

say(.name);
# .name = 'abc';
.set('name', 'abc');
say(.name);
