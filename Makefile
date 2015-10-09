NAME = fcards
EXECUTABLE = fcards

all: compile tests docs

compile:
	corebuild -pkg pa_ounit.syntax -cflags -safe-string fcards.native
#	corebuild -cflags -safe-string fcards.native

docs:
	ocamldoc -d doc -html flashcards.mli

tests:
#	./$(EXECUTABLE).native inline-test-runner

clean:
	rm -f $(EXECUTABLE).native *.aux *.dvi *.out *.log *.o *.ps *.ptb *.tex *.html *.css
	rm -rf _build
#	rm -f doc/*

clean-all:
#	rm -f $(EXECUTABLE) $(EXECUTABLE).exe *.aux *.dvi *.out *.hi *.log *.o *.ps *.ptb *.tex *.pdf *.html *.css *.gif *.png *.js
