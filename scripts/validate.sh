#!/bin/bash

if [ -z "$1" ]
  then
    echo "Usage: $0 {article.xml}"
    exit
fi

ARTICLE=$1
FILE=`basename "$ARTICLE" .xml`

# http://stackoverflow.com/questions/59895/can-a-bash-script-tell-what-directory-its-stored-in
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
XSL="$DIR/../xsl"
RESOURCES="$DIR/../resources"

OUTPUT_DIR=$(mktemp -d -t validate)

export SGML_CATALOG_FILES="$RESOURCES/catalog.xml"
#export SGML_CATALOG_FILES=catalog.xml

echo "Validating against JATS DTD"
xmllint --loaddtd --valid  --nonet --load-trace --noout --catalogs "$ARTICLE"

echo "Validating for CrossRef DOI deposition"
xsltproc --catalogs \
	--stringparam 'timestamp' `date +"%s"` \
	--stringparam 'depositorName' 'test' \
	--stringparam 'depositorEmail' 'test@example.com' \
	"$XSL/jats-to-unixref.xsl" "$ARTICLE" \
	| xmllint --nonet --load-trace --noout --schema "$RESOURCES/crossref/crossref4.3.1.xsd" -

echo "Generating CrossRef schematron report"
OUTPUT="$OUTPUT_DIR/$FILE-crossref-schematron-report.xml"
#xsltproc --catalogs --stringparam "timestamp" `date +"%s"` "$$XSL/jats-to-unixref.xsl" "$ARTICLE" | xsltproc "$RESOURCES/schematron/crossref.xsl" -
xsltproc --catalogs --stringparam "timestamp" `date +"%s"` "$XSL/jats-to-unixref.xsl" "$ARTICLE" > "$OUTPUT_DIR/crossref.xml"
saxon "$OUTPUT_DIR/crossref.xml" "$RESOURCES/crossref/schematron.xsl" > "$OUTPUT"
echo "CrossRef schematron report written to $OUTPUT"

echo "Checking PMC tagging style"
OUTPUT="$OUTPUT_DIR/$FILE-nlm-style-report.html"
xsltproc --catalogs "$RESOURCES/nlm-stylechecker/nlm-stylechecker.xsl" "$ARTICLE" | xsltproc -output "$OUTPUT" "$RESOURCES/nlm-stylechecker/style-reporter.xsl" -
echo "NLM Style report written to $OUTPUT"

echo "Generating HTML"
OUTPUT="$OUTPUT_DIR/$FILE-preview.html"
xsltproc --catalogs -output "$OUTPUT" "$XSL/jats-to-html.xsl" "$ARTICLE"
echo "HTML written to $OUTPUT"

# TODO: run JS tests in PhantomJS
