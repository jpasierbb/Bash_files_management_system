#!/bin/bash

# set -euxo pipefail # do debugowania - wypisuje na standardowe wyjście
# set -euo pipefail # do działania

# Wczytanie zmiennych z pliku i definiowanie zmiennych
source ./.clean_files
CATALOGS=()
OPTS=()
DESIRED_CATALOG="NONE"

#---------------------------------------------------
#---------------------Funkcje-----------------------
#---------------------------------------------------
function help() {
    cat << EOF
Usage: asu.sh [CATALOGS] [OPTION] [CATALOG]...
    -h  --help        Display this message
    -x  --catalog     Specify the default catalog X
    -d  --duplicates  Remove duplicates
    -e  --empty       Remove empty files
    -l  --empty-dir   Remove empty dicitonaries
    -t  --temp        Remove temporary files
    -c  --copy        Copy files to directory X specified using -x|--catalog option
    -v  --move        Move files to directory X specified using -x|--catalog option
    -r  --rename      Rename every file in the given catalogs
    -s  --same-name   Remove files with the same name
    -p  --perms       Change permissions to default value
    -m  --marks       Replace problematic characters with default
Example:
./asu.sh ./X ./Y1 ./Y2 ./Y3 --catalog ./X --duplicates --empty --temp --same-name --perms --copy --marks --default
./asu.sh ./X ./Y1 ./Y2 ./Y3 --duplicates
EOF
exit 0;
}


# Funkcja usuwajaca pliki o tej samej nazwie, zachowujaca najstarszy
function same_name_files() {
    local DO_FOR_ALL_FILES="n"
    while IFS= read -r -d $'\0' FILENAME; do
        FILES=()
        TIMES_CREATED=()
        FILE_LAST_CREATED="a"
        MAX_TIME=0

        while IFS= read -r -d $'\0' FILE; do
            FILES+=("$FILE")
            TIME=$(stat "$FILE" -c %Y)
            TIMES_CREATED+=("$TIME")

            if [[ ${TIME} -gt ${MAX_TIME} ]]; then
                MAX_TIME="$TIME"
                FILE_LAST_CREATED="$FILE"
            fi
        done < <(find "${CATALOGS[@]}" -name "$FILENAME" -print0)

        echo "here yes $DO_FOR_ALL_FILES"
        echo "Found files with the same name: ${FILES[@]}"

        if [[ "$DO_FOR_ALL_FILES" != "YES" ]]; then
            echo "Do you want to leave only: $FILE_LAST_CREATED?"
            echo "[YES] - for all files, [y/n] - for this file"
            read -p "[YES/y/n] " REMOVE_SAME_NAME </dev/tty
            if [[ "$REMOVE_SAME_NAME" = "YES" ]]; then
                DO_FOR_ALL_FILES="$REMOVE_SAME_NAME"
                echo "here yes $DO_FOR_ALL_FILES"
            fi
        fi

        if [[ "$REMOVE_SAME_NAME" = "y" || "$DO_FOR_ALL_FILES" = "YES" ]]; then
            for FILE in "${FILES[@]}"; do
                if [[ "$FILE" != "$FILE_LAST_CREATED" ]]; then
                    rm "$FILE"
                    echo "$FILE has been deleted."
                fi
            done
        fi
    done < <(find "${CATALOGS[@]}" -type f -print0 | sed 's_.*/__' -z | sort -z | uniq -z -d)
}

# Funkcja kopiujaca pliki do katalogu podanego w -x/--catalog
function move_files() {
    local DO_FOR_ALL_FILES="n"
    # Sprawdzenie czy podano odpowiednia ilosc argumentow
    if [[ "$DESIRED_CATALOG" = "NONE" || ${#CATALOGS[@]} = 0 || ${#CATALOGS[@]} = 1 ]]; then
        echo "Provide catalogs names and choose main catalog"
        echo "Example: ./asu.sh ./X ./Y --catalog ./X"
        echo "help: ./asu.sh -h"
        exit 1
    fi
    # TODO zmodyfiowac
    for CATALOG in "${CATALOGS[@]}"; do
        while IFS= read -r -d $'\0' FILENAME; do
        # Nie kopiujemy pozadanego katalogu do niego samego
        if [[ "$CATALOG" = "$DESIRED_CATALOG" ]]; then
            continue
        fi
        # Zapewnienie opcji dla wszystkich plikow
        if [[ "$DO_FOR_ALL_FILES" != "YES" ]]; then
            echo "Do you want to move the file $FILENAME to $DESIRED_CATALOG?"
            echo "[YES] - for all files, [y/n] - for this file"
            read -p "[YES/y/n] "  MOVE_FILE </dev/tty
            if [[ "$MOVE_FILE" = "YES" ]]; then
                DO_FOR_ALL_FILES="$MOVE_FILE"
            fi
        fi
        # Logika kopiowania
        if [[ "$MOVE_FILE" = "y" || "$DO_FOR_ALL_FILES" = "YES" ]]; then
            CLEAR_CATALOG=$(echo -n "$CATALOG" | sed -z 's/\//\\\//g')
            CLEAR_DEFAULT=$(echo -n "$DESIRED_CATALOG" | sed -z 's/\//\\\//g')
            NEW_FILENAME=$(echo -n "$FILENAME" | sed -z "0,/$CLEAR_CATALOG/{s/$CLEAR_CATALOG/$CLEAR_DEFAULT/}")
            mkdir -p "$(dirname "$NEW_FILENAME")"
            mv "$FILENAME" "$NEW_FILENAME"
            echo "File $FILENAME moved to $NEW_FILENAME"
        fi
        done < <(find "$CATALOG" -type f -print0)
    done
}

# Funkcja kopiujaca pliki do katalogu podanego w -x/--catalog
function copy_files() {
    local DO_FOR_ALL_FILES="n"
    # Sprawdzenie czy podano odpowiednia ilosc argumentow
    if [[ "$DESIRED_CATALOG" = "NONE" || ${#CATALOGS[@]} = 0 || ${#CATALOGS[@]} = 1 ]]; then
        echo "Provide catalogs names and choose main catalog"
        echo "Example: ./asu.sh ./X ./Y --catalog ./X"
        echo "help: ./asu.sh -h"
        exit 1
    fi
    for CATALOG in "${CATALOGS[@]}"; do
        while IFS= read -r -d $'\0' FILENAME; do
        # Nie kopiujemy pozadanego katalogu do niego samego
        if [[ "$CATALOG" = "$DESIRED_CATALOG" ]]; then
            continue
        fi
        # Zapewnienie opcji dla wszystkich plikow
        if [[ "$DO_FOR_ALL_FILES" != "YES" ]]; then
            echo "Do you want to copy the file $FILENAME to $DESIRED_CATALOG?"
            echo "[YES] - for all files, [y/n] - for this file"
            read -p "[YES/y/n] "  COPY_FILE </dev/tty
            if [[ "$COPY_FILE" = "YES" ]]; then
                DO_FOR_ALL_FILES="$COPY_FILE"
            fi
        fi
        # Logika kopiowania
        if [[ "$COPY_FILE" = "y" || "$DO_FOR_ALL_FILES" = "YES" ]]; then
            CLEAR_CATALOG=$(echo -n "$CATALOG" | sed -z 's/\//\\\//g')
            CLEAR_DEFAULT=$(echo -n "$DESIRED_CATALOG" | sed -z 's/\//\\\//g')
            NEW_FILENAME=$(echo -n "$FILENAME" | sed -z "0,/$CLEAR_CATALOG/{s/$CLEAR_CATALOG/$CLEAR_DEFAULT/}")
            mkdir -p "$(dirname "$NEW_FILENAME")"
            cp -r -- "$FILENAME" "$NEW_FILENAME"
            echo "File $FILENAME copied to $NEW_FILENAME"
        fi
        done < <(find "$CATALOG" -type f -print0)
    done
}

# Funkcja usuwajaca duplikacjace sie pliki wzgledem pierwszego podanego katalogu
function duplicate_files() {
    local DO_FOR_ALL_FILES="n"
    local FILES=()
    local PREVIOUS_HASH=""

    while IFS= read -r -d $'\0' HASH_FILENAME; do
        FILENAME=$(echo "$HASH_FILENAME" | sed -n 's/^[[:alnum:][:punct:]]\{32\}\s*//p')
        HASH=$(echo "$HASH_FILENAME" | sed 's/\s.*$//')
        if [[ "$PREVIOUS_HASH" != "$HASH" ]]; then
            if [[ "$PREVIOUS_HASH" != "" ]]; then
                echo Detected duplicate files: "${FILES[@]}"
                TIMES_CREATED=()

                FILE_CREATED_FIRST="$FILES"
                MIN_TIME=$(stat "$FILE_CREATED_FIRST" -c %Y)

                for FILE in "${FILES[@]}"; do
                    TIME=$(stat "$FILE" -c %Y)
                    TIMES_CREATED+=("$TIME")

                    if [[ ${MIN_TIME} -gt ${TIME} ]]; then
                        MIN_TIME="$TIME"
                        FILE_CREATED_FIRST="$FILE"
                    fi
                done

                echo "F: $FILE"
                if [[ "$DO_FOR_ALL_FILES" != "YES" ]]; then
                    echo "Do you want to remove all the duplicates and leave only: $FILE_CREATED_FIRST?"
                    echo "[YES] - for all files, [y/n] - for this file"
                    read -p "[YES/y/n] "  REMOVE_DUPLICATES </dev/tty
                    if [[ "$REMOVE_DUPLICATES" = "YES" ]]; then
                        DO_FOR_ALL_FILES="$REMOVE_DUPLICATES"
                    fi
                fi
                if [[ "$REMOVE_DUPLICATES" = "y" || "$DO_FOR_ALL_FILES" = "YES" ]]; then
                    for FILE in "${FILES[@]}"; do
                        if [[ "$FILE" != "$FILE_CREATED_FIRST" ]]; then
                            rm "$FILE"
                            echo "$FILE has been deleted."
                        fi
                    done
                fi

            fi
            FILES=("$FILENAME")
            PREVIOUS_HASH="$HASH"
        else
            FILES+=("$FILENAME")
        fi
    done < <(find "${CATALOGS[@]}" -type f -print0 | xargs -0 md5sum | awk -v ORS='\0' -v FS='\n' '{print $1 $2}' | sort -k1,32 -z | uniq -w32 -z -D)
}

# Funkcja zmieniajaca nazwe pliku
function rename_files() {
    local DO_FOR_ALL_FILES="n"
    while IFS= read -r -d $'\0' FILENAME; do
        if [[ "$DO_FOR_ALL_FILES" != "YES" ]]; then
            echo "Do you want to rename file: $FILENAME?"
            echo "[YES] - for all files, [y/n] - for this file"
            read -p "[YES/y/n] "  RENAME_FILE </dev/tty
            if [[ "$RENAME_FILE" = "YES" ]]; then
                DO_FOR_ALL_FILES="$RENAME_FILE"
            fi
        fi

        if [[ "$RENAME_FILE" = "y" || "$DO_FOR_ALL_FILES" = "YES" ]]; then
            read -p "Provide new name: " NEW_FILENAME </dev/tty
            mv -- "$FILENAME" "$NEW_FILENAME"
            echo "Replaced $FILENAME with $NEW_FILENAME"
        else
            echo "Name: $FILENAME did not changed."
        fi
    done < <(find "${CATALOGS[@]}" -type f -print0)
}

# Funkcja usuwajaca puste katalogi
function empty_dirs() {
    local DO_FOR_ALL_DIRS="n"
    while IFS= read -r -d $'\0' DIRNAME; do
        if [ -z "$(find "$DIRNAME" -type f)" ]; then
            if [[ "$DO_FOR_ALL_DIRS" != "YES" ]]; then
                echo "Do you want to remove an empty dictionary: $DIRNAME?"
                echo "[YES] - for all dictionaries, [y/n] - for this dictionary"
                read -p "[YES/y/n] "  REMOVE_EMPTY </dev/tty
                if [[ "$REMOVE_EMPTY" = "YES" ]]; then
                    DO_FOR_ALL_DIRS="$REMOVE_EMPTY"
                fi
            fi

            if [[ "$REMOVE_EMPTY" = "y" || "$DO_FOR_ALL_DIRS" = "YES" ]]; then
                rm -r "$DIRNAME"
                echo "$DIRNAME has been removed."
            fi
        fi
    done < <(find "${CATALOGS[@]}" -type d -empty -print0)
}

# Funkcja usuwajaca puste pliki
function empty_files() {
    local DO_FOR_ALL_FILES="n"
    while IFS= read -r -d $'\0' FILENAME; do
        if [[ "$DO_FOR_ALL_FILES" != "YES" ]]; then
            echo "Do you want to remove an empty file: $FILENAME?"
            echo "[YES] - for all files, [y/n] - for this file"
            read -p "[YES/y/n] "  REMOVE_EMPTY </dev/tty
            if [[ "$REMOVE_EMPTY" = "YES" ]]; then
                DO_FOR_ALL_FILES="$REMOVE_EMPTY"
            fi
        fi

        if [[ "$REMOVE_EMPTY" = "y" || "$DO_FOR_ALL_FILES" = "YES" ]]; then
            rm "$FILENAME"
            echo "$FILENAME has been removed."
        fi
    done < <(find "${CATALOGS[@]}" -type f -size 0 -print0)
}

# Funkcja usuwajaca tymczasowe pliki
function temp_files() {
    local DO_FOR_ALL_FILES="n"
    while IFS= read -r -d $'\0' FILENAME; do
        if [[ "$DO_FOR_ALL_FILES" != "YES" ]]; then
            echo "Do you want to remove a temporary file: $FILENAME?"
            echo "[YES] - for all files, [y/n] - for this file"
            read -p "[YES/y/n] "  RMV_TMP </dev/tty
            if [[ "$RMV_TMP" = "YES" ]]; then
                DO_FOR_ALL_FILES="$RMV_TMP"
            fi
        fi

        if [[ "$RMV_TMP" = "y" || "$DO_FOR_ALL_FILES" = "YES" ]]; then
            rm "$FILENAME"
            echo "$FILENAME has been removed."
        fi
    done < <(find "${CATALOGS[@]}" -type f -regex "$TMP_FILES" -print0)
}

# Funkcja zmienia dostepy do plikow
function change_perms() {
    local DO_FOR_ALL_FILES="n"
    while IFS= read -r -d $'\0' FILENAME; do
        echo "Detected file with permissions you may be willing to change: $FILENAME"
        permissions_number=$(stat -c "%a" "$FILENAME")
        permissions_symbol=$(stat -c "%A" "$FILENAME")
        echo "Current permissions: "$permissions_number" (number)  "$permissions_symbol" (symbol)"
        if [[ "$DO_FOR_ALL_FILES" != "YES" ]]; then
            echo "Do you want to change permissions to default value $SUGGESTED_ACCESS?"
            echo "[YES] - for all files, [y/n] - for this file"
            read -p "[YES/y/n] "  CHANGE_PERMS </dev/tty
            if [[ "$CHANGE_PERMS" = "YES" ]]; then
                DO_FOR_ALL_FILES="$CHANGE_PERMS"
            fi
        fi

        if [[ "$CHANGE_PERMS" = "y" || "$DO_FOR_ALL_FILES" = "YES"  ]]; then
            chmod 000 "$FILENAME"
            chmod $SUGGESTED_ACCESS "$FILENAME"
            echo "Changed perms for $FILENAME to $SUGGESTED_ACCESS"
        fi
    done < <(find "${CATALOGS[@]}" -type f -not -perm "$SUGGESTED_ACCESS" -print0)
}

# Funkcja zamienia problematyczne nazwy plikow, tj. zawierajace znaki \"”;*?\$#'‘|\\,'
function find_marks() {
    local DO_FOR_ALL_FILES="n"
    while IFS= read -r -d $'\0' FILENAME; do
        # Pominiecie, jesli wyrazenie wylapano przez nazwe pliku
        result=$(echo "${FILENAME##*/}" | grep -a "[${CHARACTERS_TO_CHANGE}]")
        if [[ -z "$result" ]]; then
            continue
        fi
        echo "Detected the file to change name: $FILENAME"
        if [[ "$DO_FOR_ALL_FILES" != "YES" ]]; then
            echo "Are you sure to remove problematic characters and change a name?"
            echo "[YES] - for all files, [y/n] - for this file"
            read -p "[YES/y/n] "  CHANGE_CHARACTERS </dev/tty
            if [[ "$CHANGE_CHARACTERS" = "YES" ]]; then
                DO_FOR_ALL_FILES="$CHANGE_CHARACTERS"
            fi
        fi

        if [[ "$CHANGE_CHARACTERS" = "y" || "$DO_FOR_ALL_FILES" = "YES" ]]; then
            # Rozdzielenie sciezki i nazwy pliku
            path_only="${FILENAME%/*}"
            filename_only="${FILENAME##*/}"
            # Zmiana nazwy pliku
            NEW_NAME=$(echo "$filename_only" | sed "s/[${CHARACTERS_TO_CHANGE}]/${CHARACTERS_TO_CHANGE_SUBSTITUTE}/g")
            # Dodanie nazwy pliku do sciezki
            new_full_path="$path_only/$NEW_NAME"
            # Zmiana nazwy + komunikat
            mv -- "$FILENAME" "$new_full_path"
            echo "Replaced $FILENAME with $new_full_path"
        else
            echo "Name: $FILENAME did not changed."
        fi
    done < <(find "${CATALOGS[@]}" -type f -print0 | grep -a -z "[${CHARACTERS_TO_CHANGE}]")
}

#---------------------------------------------------
#----------------Parsowanie args--------------------
#---------------------------------------------------
while [[ $# -gt 0 ]]; do
  case $1 in
    -h|--help)
        help
        ;;
    -x|--catalog)
        DESIRED_CATALOG="$2"
        shift
        shift
        ;;
    -d|--duplicates)
        OPTS+=("DUPLICATES")
        shift
        ;;
    -e|--empty)
        OPTS+=("EMPTY")
        shift
        ;;
    -t|--temp)
        OPTS+=("TEMP")
        shift
        ;;
    -c|--copy)
        OPTS+=("COPY")
        shift
        ;;
    -r|--rename)
        OPTS+=("RENAME")
        shift
        ;;
    -s|--same-name)
        OPTS+=("SAME")
        shift
        ;;
    -p|--perms)
        OPTS+=("PERMS")
        shift
        ;;
    -m|--marks)
        OPTS+=("MARKS")
        shift
        ;;
    -v|--move)
        OPTS+=("MOVE")
        shift
        ;;
    -l|--empty-dir)
        OPTS+=("EMPTYDIR")
        shift
        ;;
    -*|--*)
        echo "Unknown option $1" 1>&2
        help
        exit 1
        ;;
    *)
        CATALOGS+=("$1")
        shift
        ;;
    esac
done

#---------------------------------------------------
#----------------Wykonanie skryptu------------------
#---------------------------------------------------

# Sprawdzenie, czy zmienna OPERATIONS jest pusta
if [ ${#OPTS[@]} -eq 0 ]; then
    echo "Error: No operations specified." >&2
    help
    exit 1
fi

# Iteracja po podanych argumentach i wywołanie funkcji
for OPT in "${OPTS[@]}"; do
    case "$OPT" in
        MARKS)
            find_marks
            ;;
        PERMS)
            change_perms
            ;;
        TEMP)
            temp_files
            ;;
        EMPTY)
            empty_files
            ;;
        RENAME)
            rename_files
            ;;
        COPY)
            copy_files
            ;;
        DUPLICATES)
            duplicate_files
            ;;
        SAME)
            same_name_files
            ;;
        MOVE)
            move_files
            ;;
        EMPTYDIR)
            empty_dirs
            ;;
    esac
done
