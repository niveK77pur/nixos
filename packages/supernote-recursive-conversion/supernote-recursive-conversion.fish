#!/usr/bin/env fish
# vim: fdm=marker

argparse 'i/input-dir=' 'o/output-dir=' init-pdfs shadb= -- $argv
or return

if ! set -q _flag_input_dir
    echo "--input-dir / -i is required"
    exit 1
end
if ! set -q _flag_output_dir
    echo "--output-dir / -i is required"
    exit 1
end

set -lx SHADB $_flag_shadb
if ! set -q _flag_shadb
    set SHADB ./supernote-recursive-conversion-shadb
end

set -lx INPUT_DIR (realpath $_flag_input_dir)

mkdir -p $_flag_output_dir
set -lx OUTPUT_DIR (realpath $_flag_output_dir)

## Helper functions ##

#  {{{1
function get_hashes -d "Compute hashes for all .note files"
    find $INPUT_DIR -type f -name "*.note" -exec xxhsum -H2 {} +
end

#  {{{1
function snconvert -a infile outfile -d "Helper to convert .note files to .pdf"
    mkdir -p (dirname $outfile)
    supernote-tool convert --all --type pdf $infile $outfile
end

#  {{{1
function infile2outfile -a note_file -d "Map input file to the corresponding output file"
    set -f outfile (string replace -r '\.note$' '.pdf' $note_file)
    set -f outfile (string replace $INPUT_DIR $OUTPUT_DIR $outfile)
    printf "%s" $outfile
end

#  {{{1
function note_convert -a note_file -d "Convert files and add/update the $SHADB"
    set -f hash_line (xxhsum -H2 $note_file)
    set -f hashNR (grep --max-count 1 --line-number --fixed-strings $note_file $SHADB | string split -f1 :)
    if test "$hashNR" != ""
        echo Updating file $note_file
        sed -i "$hashNR s:.*:$hash_line:" $SHADB
    else
        echo Adding file $note_file
        printf "%s\n" $hash_line >>$SHADB
    end
    snconvert $note_file (infile2outfile $note_file)
end

#  {{{1
function note_remove -a note_file -d "Remove converted file and remove from $SHADB"
    echo "Removing file '$(infile2outfile $note_file)'"
    set -f hashNR (grep --max-count 1 --line-number --fixed-strings $note_file $SHADB | string split -f1 :)
    if test "$hashNR" != ""
        sed -i "$hashNR d" $SHADB
    end
    rm -f -- (infile2outfile $note_file)
end

#  {{{1
function sync_shadb -d "Check and update file states compared to the \$SHADB"
    # Check how files have changed. We perform this elaborate processing to
    # distinguish between addition, removal, and change. `diff` in this case
    # will report a "change" as both an addition and a deletion, which -
    # depending on their ordering - may lead to an unintended deletion of the
    # file (i.e. first reports an addition -> trigger conversion; then report
    # deletion -> trigger deletion; end result: file gone instead of updated).
    set -l changes (diff --unchanged-line-format="" --old-line-format="-%c'\011'%L" --new-line-format="+%c'\011'%L" \
        (sed 's/\s\+/\t/' $SHADB | psub) \
        (get_hashes | sed 's/\s\+/\t/' | psub) \
        | awk -F\t '
            {
                if($1 == "-") {
                    if($3 in ADDED) {
                        delete ADDED[$3]; CHANGED[$3]++
                    } else {
                        REMOVED[$3]++
                    }
                } else if($1 == "+") {
                    if($3 in REMOVED) {
                        delete REMOVED[$3]; CHANGED[$3]++
                    } else {
                        ADDED[$3]++
                    }
                }
            } END {
                for (key in ADDED) {print "+\t" key}
                for (key in REMOVED) {print "-\t" key}
                for (key in CHANGED) {print "~\t" key}
            }
            ')

    for c in $changes
        set -l line (string split '	' -- "$c")
        switch $line[1]
            case "+"
                note_convert $line[2]
            case -
                note_remove $line[2]
            case "~"
                note_convert $line[2]
        end
    end
end

#  }}}1

## Startup ##

if ! test -f $SHADB
    ## Initialize $SHADB ##
    touch $SHADB
    if set -q _flag_init_pdfs
        for note_file in (find $INPUT_DIR -type f -name "*.note")
            note_convert $note_file
        end
    else
        echo Generating initial hashes for all .note files ...
        get_hashes >$SHADB
    end
else
    sync_shadb
end
