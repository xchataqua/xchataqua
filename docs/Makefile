#
# makefile for generating xchat documentation pdf
#

all: main

main: main.tex Makefile
	pdflatex main.tex
	makeindex main.idx
	pdflatex main.tex
	pdflatex main.tex
clean::
	rm -rf *.aux *.toc *.glo *.log *.ilg *.idx *.ind
