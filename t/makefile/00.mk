# comment...

VAR = "test" # comment
V2 = test"test"test

FOO$(VAR)BAR = test

$(info $(VAR))
$(info $(V2))
$(info FOO$(VAR)BAR)
$(info $(FOO$(VAR)BAR))
$(info $(FOOtestBAR))

$(warning "$(FOO$(VAR)BAR), $(FOOtestBAR)")

foo : bar1 bar2 | baz1 baz2
	echo $@ $^ $(VAR)
bar1:
	echo $@ $(V2)
bar2:
	echo $@ $(V2)
baz1:
	echo $@ \
a b c \
	defgh
baz2:
	echo $@
