OBJDIR = obj
BINDIR = bin
LIBDIR = calculator
APIDIR = api
TESTDIR = tests

LANGUAGE = -XQuasiQuotes
GHC_OPTIONS = -hidir obj -odir obj -O -j4 -fhpc -no-user-package-db -package-db .cabal-sandbox/*-packages.conf.d/ $(LANGUAGE)
INCLUDES = -i$(LIBDIR) -i$(APIDIR)

StartTestServer = $(BINDIR)/test_server > /dev/null 2>&1 &
KillTestServer = @killall test_server

server: $(APIDIR)/Server.hs | $(BINDIR)
		@echo "Building server"
		ghc $< $(INCLUDES) $(GHC_OPTIONS) -o $(BINDIR)/server

test_server: $(TESTDIR)/TestServer.hs | $(BINDIR)
		@echo "Building test server"
		ghc $< $(INCLUDES) $(GHC_OPTIONS) -o $(BINDIR)/test_server

.PHONY: tests
tests: int_tests e2e_tests api_tests

int_tests: $(TESTDIR)/integration/TestSuite.hs | $(BINDIR)
		@echo "Building integration tests"
		@rm -rf *.tix .hpc/
		ghc $< $(INCLUDES) -i$(TESTDIR)/integration $(GHC_OPTIONS) -o $(BINDIR)/tests
		-$(BINDIR)/tests

e2e_tests: test_server
		$(StartTestServer)
		-protractor $(TESTDIR)/protractor.conf.js
		$(KillTestServer)

api_tests: test_server
		$(StartTestServer)
		-mocha tests/api -R spec
		$(KillTestServer)

$(OBJDIR) $(BINDIR):
		@mkdir -p $@

clean:
		@echo "Cleaning..."
		@sudo rm -rf state/ $(OBJDIR) .hpc/ *.tix

.PHONY: tags
tags:
		@echo "Making calculator tags"
		@echo ":ctags" | ./repl -v0 calculator/Calculator.hs
		@echo "Making api tags"
		@echo ":ctags" | ./repl -v0 api/TextToMath.hs
		@echo "Making test tags"
		@echo ":ctags" | ./repl -v0 tests/integration/TestSuite.hs
