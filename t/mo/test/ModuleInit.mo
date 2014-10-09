say('1..3');

init {
  if +@_ == 3
    if @_[0] eq 'param-1'
      say('ok - @_[0] = param-1')
    end
    if @_[1] eq 'param-2'
      say('ok - @_[1] = param-2')
    end
    if @_[2] == 123
      say('ok - @_[2] = 123')
    end
  end
}
