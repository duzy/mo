# comment...

VAR = "test" # comment

FOO$(VAR)BAR = test

$(info test)
$(info $(FOO$(VAR)BAR))
$(info $(FOOtestBAR))

foo : bar | baz
	echo $@
bar:
	echo $@
