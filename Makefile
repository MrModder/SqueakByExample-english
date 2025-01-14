# --------------------------------------------------------------------------------
# $Id$
# --------------------------------------------------------------------------------

# export TEXINPUTS:=.:local
export TEXINPUTS:=./local//:../local//:

C = Preface QuickTour FirstApp Syntax Messages \
	Model Environment SUnit BasicClasses Collections Streams Morphic \
	Metaclasses

PDFLATEX = pdflatex -file-line-error
BIBTEX=bibtex
BOOK=SBE
ETC=SBE-etc

# --------------------------------------------------------------------------------
all : book

# NB: be sure to use texlive and to set the TEXINPUTS variable accordingly
# See README.txt

book : clean examples
	time ${PDFLATEX} ${BOOK}
	time ${BIBTEX} ${BOOK}
	time ${PDFLATEX} ${BOOK}
	time ${PDFLATEX} ${BOOK} | tee warnings.txt
	# Filter out blank lines and bogus warnings
	perl -pi \
		-e '$$/ = "";' \
		-e 's/[\n\r]+/\n/g;' \
		-e 's/LaTeX Warning: Label `\w*:defaultlabel'\'' multiply defined.[\n\r]*//g;' \
		-e 's/Package wrapfig Warning: wrapfigure used inside a conflicting environment[\n\r]*//g;' \
		warnings.txt


# We need a makefile rule to generate the index as well ...
index :
	makeindex ${BOOK}

complete : book index
	time ${PDFLATEX} ${BOOK}

etc :
	time ${PDFLATEX} ${ETC}
	makeindex ${ETC}
	time ${PDFLATEX} ${ETC}
	time ${PDFLATEX} ${ETC}
	open ${ETC}.pdf

examples :
	./examples.rb $C > $@.txt

fun :
	time ./examples.rb $C > $@1.txt
	# Requires Gnu Smalltalk 2.95c with scripting support:
	time ./examples.st $C > $@2.txt
	-diff $@1.txt $@2.txt

# --------------------------------------------------------------------------------
# MAINTENANCE

# Adapt this rule to find anything (such as duplicate labels)
find :
	find . -name \*.tex | \
	xargs egrep '\\atsign'

# Search for any figure files with non-unique names
duplicates :
	ls figures */figures | sort | uniq -d

# look for bad usages of see index (with ! in second arg)
badsee :
	find . -name \*.tex | \
	xargs egrep '\\seeindex\{.*}{.*!.*}'

badindex :
	find . -name \*.tex | \
	xargs egrep '\\index\{.*}{'

# Check for duplicate labels
checkLabels :
	find . -name \*.tex | \
	xargs perl -p -e 's/\%.*//;' | \
	fgrep '\label' | \
	perl -p -e 's/.*\\label{([^}]*)}.*/$$1/;' | \
	sort | uniq -d

# Count deprecated stuff:
deprecated :
	# @ echo "OLDscript:"
	# @find . -name \*.tex | xargs fgrep '{OLDscript}' | sed 's/:.*//' | sort | uniq -c
	@ echo "doublebox:"
	@find . -name \*.tex | xargs fgrep 'doublebox' | sed 's/:.*//' | sort | uniq -c

munge :
	find . -name \*.tex | \
	xargs perl -pi \
	-e 's/{Chapter summary}/{Chapter Summary}/g;'

keys :
	find . -name \*.tex -or -name \*.txt | \
	xargs svn propset svn:keywords "Date Author Id Log"

# Fix the mime types of all pdf files
ps :
	find . -name \*.pdf | \
	xargs svn ps svn:mime-type application/octet-stream

# --------------------------------------------------------------------------------
clean :
	-rm -f *.aux *.log *.out *.glo *.toc *.ilg *.blg *.idx
	-rm -f */*.aux */*.log */*.out
	-rm -f .DS_Store */.DS_Store
	-rm -f common*.url common*.pdf SBE.url
	-rm -f test.*

bare : clean
	mv figures/squeak-logo.pdf figures/squeak-logo.pdfSAVE
	-rm -f ${BOOK}.pdf */*.pdf
	mv figures/squeak-logo.pdfSAVE figures/squeak-logo.pdf

# --------------------------------------------------------------------------------
