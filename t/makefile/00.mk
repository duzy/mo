# comment...

VAR = "test" # comment
V2 = test"test"test

FOO$(VAR)BAR = test

$(info $(VAR))
$(info $(V2))
$(info FOO$(VAR)BAR)
$(info $(FOO$(VAR)BAR))
$(info $(FOOtestBAR))

foo : bar | baz
	echo $@ $(VAR)
bar:
	echo $@ $(V2)
baz:
	echo $@
