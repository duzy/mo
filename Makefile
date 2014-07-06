PARROT := $(shell which parrot)
BASH := $(shell which bash)
NQP := $(shell which nqp-p) --module-path=gen
CAT := $(shell which cat)

XML_PBC := gen/xml.pbc
XML_PIR := gen/xml.pir
XML_NQP := gen/xml.nqp
XML_SOURCES := \
  src/xml/Grammar.nqp \
  src/xml/Actions.nqp \
  src/xml/Compiler.nqp \
  src/xml/World.nqp \
  src/xml/Node.nqp \

MO_PBC := gen/mo.pbc
MO_PIR := gen/mo.pir
MO_NQP := gen/mo.nqp
MO_SOURCES := \
  src/mo/Grammar.nqp \
  src/mo/Actions.nqp \
  src/mo/Compiler.nqp \
  src/mo/World.nqp \

$(MO_PBC): $(MO_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(MO_PIR): $(MO_NQP) $(XML_PBC)
	@mkdir -p $(@D)
	$(NQP) --target=pir --output="$@" "$<"
	@[ -f $@ ]

$(MO_NQP): $(MO_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"

$(XML_PBC): $(XML_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(XML_PIR): $(XML_NQP)
	@mkdir -p $(@D)
	$(NQP) --target=pir --output="$@" "$<"
	@[ -f $@ ]

$(XML_NQP): $(XML_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"

test: test-xml test-json test-mo

test-xml: t/xml/run.bash $(XML_PBC)
	@$(BASH) $<

test-json: ; @echo "JSON..."

test-mo: t/mo/run.bash $(MO_PBC)
	@$(BASH) $<

