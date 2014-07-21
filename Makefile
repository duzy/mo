PARROT := $(shell which parrot)
BASH := $(shell which bash)
NQP := $(shell which nqp-p) --module-path=gen
CAT := $(shell which cat)

COMMON_PBC := gen/common.pbc
COMMON_PIR := gen/common.pir
COMMON_NQP := gen/common.nqp
COMMON_SOURCES := \
  src/how/NodeClassHOW.nqp \

JSON_PBC := gen/json.pbc
JSON_PIR := gen/json.pir
JSON_NQP := gen/json.nqp
JSON_SOURCES := \
  src/json/Grammar.nqp \

XML_PBC := gen/xml.pbc
XML_PIR := gen/xml.pir
XML_NQP := gen/xml.nqp
XML_SOURCES := \
  src/xml/Grammar.nqp \
  src/xml/Actions.nqp \
  src/xml/Compiler.nqp \
  src/xml/World.nqp \

MO_PBC := gen/mo.pbc
MO_PIR := gen/mo.pir
MO_NQP := gen/mo.nqp
MO_SOURCES := \
  src/mo/Grammar.nqp \
  src/mo/Actions.nqp \
  src/mo/Compiler.nqp \
  src/mo/Model.nqp \
  src/mo/World.nqp \

$(MO_PBC): $(MO_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(MO_PIR): $(MO_NQP) $(XML_PBC) $(JSON_PBC)
	@mkdir -p $(@D)
	$(NQP) --combine --target=pir --output="$@" $<
	@[ -f $@ ]

$(MO_NQP): $(MO_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"
	@[ -f $@ ]

$(XML_PBC): $(XML_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(XML_PIR): $(XML_NQP) $(COMMON_PBC)
	@mkdir -p $(@D)
	$(NQP) --combine --target=pir --output="$@" $<
	@[ -f $@ ]

$(XML_NQP): $(XML_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"
	@[ -f $@ ]

$(JSON_PBC): $(JSON_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(JSON_PIR): $(JSON_NQP)
	@mkdir -p $(@D)
	$(NQP) --combine --target=pir --output="$@" $^
	@[ -f $@ ]

$(JSON_NQP): $(JSON_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"
	@[ -f $@ ]

$(COMMON_PBC): $(COMMON_PIR)
	@mkdir -p $(@D)
	$(PARROT) -t=pbc --output="$@" "$<" 2>/dev/null
	@[ -f $@ ]

$(COMMON_PIR): $(COMMON_NQP)
	@mkdir -p $(@D)
	$(NQP) --combine --target=pir --output="$@" "$^"
	@[ -f $@ ]

$(COMMON_NQP): $(COMMON_SOURCES)
	@mkdir -p $(@D)
	$(CAT) $^ > "$@"
	@[ -f $@ ]

test: test-xml test-json test-mo

test-xml: t/xml/run.bash $(XML_PBC)
	@$(BASH) $<

test-json: ; @echo "JSON..."

test-mo: t/mo/run.bash $(MO_PBC)
	@$(BASH) $<

