#!/usr/bin/env bash
#
# shellcheck disable=SC2002  # Useless cat.

# shellcheck disable=SC2034  # FORCE appears unused
FORCE="$1"
SYNTAX="$2"
EXTENSION="$3"
OUTPUTDIR="$4"
INPUT="$5"
CSSFILE="$6" # Not used bad concatenation

FILE=$(basename "$INPUT")
FILENAME=$(basename "$INPUT")
FILENAME=${FILENAME%%.md}
FILEPATH=${INPUT%"$FILE"}
OUTDIR=${OUTPUTDIR%"$FILEPATH"*}
OUTPUT="$OUTDIR"/$FILENAME


# Define $MATH
HAS_MATH=$(grep -o "\$\$.\+\$\$" "$INPUT")
if [ -n "$HAS_MATH" ]; then
  MATH="--mathjax=https://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS-MML_HTMLorMML"
else
  MATH=""
fi


# Compile for unix (with pandoc & Perl)
# TODO if there is no level2 afeter level1 ?
munix(){
  [[ "$INPUT" =~ '/diary/' ]] && return
  # Read metadata
  meta=$(perl -0777 -ne '$_ =~ /^ *---(.+?)---/s ; $res .= $1; END { print $res; }' "$INPUT");

  # Read `wiki_css:` in metadata
  CSSFILE=$(realpath --relative-to="$OUTDIR" "$HOME/wiki/wiki_hthttps://raw.githubusercontent.com/tinmarino/wiki_html/master/Css/include.css")
  export CSS_EMBED=$(echo -e "$meta" | perl -0777 -ne 'while ($_ =~ /^wiki_css:(.+)$/mg) {$res .= " -c " . ($1 =~ s/,/ -c /gr)}; print substr $res, 4')
  [ "$CSS_EMBED" ] && export CSSFILE="$CSS_EMBED"

  # Read `wiki_pandoc:` in metadata
  export PANDOC=$(echo -e "$meta" | perl -0777 -ne 'while ($_ =~ /^wiki_pandoc:(.+)$/mg) {print $1}')

  # Convertion pipeline
  cat "$INPUT" |
  # Add h3-section betewwen h3/h2 headings and end
  #
  # Newline after title
  perl -pe ' s/(\s*)(#.*)/\n\2/;' |
  # Replace vim by language-vim for prism color higlight
  perl -pe ' s/```vim/```language-vim/;' |
  # Change links: add html
  perl -pe  ' s/(\[.+?\])\(([^#)]+?)\)/\1(\2.html)/g;' |
  # Double the new line before code
  perl -0pe ' s/((^|\n\S)[^\n]*)\n\t([^*])/\1\n\n\t\3/g;' |
  # Remove spaces in void lines
  perl -lpe ' s/^\s*$//;' |
  # Debug
  # tee test.md |
  # Compile: can add  --standalone --self-contained and --include-header=<file>
  pandoc \
    $MATH $PANDOC \
    --highlight-style breezedark \
    --section-divs \
    -f "$SYNTAX" \
    -t html \
    -T "$FILE" \
    -c "$CSSFILE" \
    > "$OUTPUT.html"
  echo -e "Css: $CSSFILE \nPandoc: $PANDOC \nMeta: $meta"
}


# Obsolete ?
mtermux(){
  cat "$INPUT" |
  perl -pe  ' s/(\[.+\])\(([^#)]+)\)/\1(\2.html)/g' |
	python -m markdown |
	sed -r 's/<li>(.*)\[ \]/<li class="todo done0">\1/g; s/<li>(.*)\[X\]/<li class="todo done4">\1/g' >"$OUTPUT.html"
	# pandoc $MATH -s -f $SYNTAX -t html -c $CSSFILENAME | \
}


# Main
mmain(){
  tmp=$(uname -a)
  
  shopt -s nocasematch
  if [[ "$tmp" =~ "android" ]] ; then
  	mtermux
  else
  	munix
  fi
}


# Start
mmain
