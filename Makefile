JULIAHOME = $(shell pwd)

include ./Make.inc

default: debug

debug release: %: julia-% pcre_h.j sys.ji custom.j

julia-debug julia-release: %: src/%
	ln -f $< $@
	ln -f $< julia

src/julia-debug src/julia-release: src/%:
	$(MAKE) -C src $*

sys.ji: sysimg.j start_image.j src/boot.j src/dump.c *.j
	./julia -b sysimg.j

custom.j:
	if [ ! -f custom.j ]; then touch custom.j; fi

PCRE_CONST = 0x[0-9a-fA-F]+|[-+]?\s*[0-9]+

pcre_h.j:
	cpp -dM $(EXTROOT)/include/pcre.h | perl -nle '/^\s*#define\s+(PCRE\w*)\s*\(?($(PCRE_CONST))\)?\s*$$/ and print "$$1 = $$2"' | sort > $@

test: debug
	./julia tests.j

testall: test
	./julia test_utf8.j

SLOCCOUNT = sloccount \
	--addlang makefile \
	--personcost 100000 \
	--effort 3.6 1.2 \
	--schedule 2.5 0.32 \
	--

J_FILES = $(shell git ls-files | grep '.j$$')

sloccount:
	@for x in $(J_FILES); do cp $$x $${x%.j}.hs; done
	git ls-files | sed 's/\.j$$/.hs/' | xargs $(SLOCCOUNT) | sed 's/haskell/*julia*/g'
	@for x in $(J_FILES); do rm -f $${x%.j}.hs; done

clean:
	rm -f julia julia-{debug,release}
	rm -f pcre_h.j
	rm -f *.ji
	rm -f *~ *#
	$(MAKE) -C src clean

cleanall: clean
	$(MAKE) -C src cleanother

.PHONY: debug release test testall sloccount clean cleanall
