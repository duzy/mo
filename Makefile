PARROT := $(shell which parrot)
BASH := $(shell which bash)
NQP := $(shell which nqp-p)
CAT := $(shell which cat)

XML_PBC := gen/xml.pbc
XML_PIR := gen/xml.pir
XML_NQP := gen/xml.nqp
XML_SOURCES := \
  src/xml/Grammar.nqp \
  src/xml/Actions.nqp \
  src/xml/Compiler.nqp \

MO_PBC := gen/mo.pbc
MO_PIR := gen/mo.pir
MO_NQP := gen/mo.nqp
MO_SOURCES := \
  src/mo/Grammar.nqp \
  src/mo/Actions.nqp \
  src/mo/Compiler.nqp \

$(MO_PBC): $(MO_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<"
	@[ -f $@ ]

$(MO_PIR): $(MO_NQP)
	@mkdir -p $(@D)
	$(NQP) --target=pir --output="$@" "$<"
	@[ -f $@ ]

$(MO_NQP): $(MO_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"

$(XML_PBC): $(XML_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<"
	@[ -f $@ ]

$(XML_PIR): $(XML_NQP)
	@mkdir -p $(@D)
	$(NQP) --target=pir --output="$@" "$<"
	@[ -f $@ ]

$(XML_NQP): $(XML_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"

test: test-xml test-mo

test-xml: t/xml/run.bash $(XML_PBC)
	@$(BASH) $<

test-mo:
