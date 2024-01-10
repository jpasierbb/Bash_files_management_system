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
    -h --help        Display this message
    -x --catalog     Specify the default catalog X
    -d --duplicates  Remove duplicates
    -e --empty       Remove empty files
    -t --temp        Remove temporary files
    -c --copy        Copy files to directory X
    -r --rename      Rename every file in the given catalogs
    -s --same-name   Remove files with the same name
    -p --perms       Change permissions to default value
    -m --marks       Replace problematic characters with default
Example:
./asu.sh ./X ./Y1 ./Y2 ./Y3 --catalog ./X --duplicates --empty --temp --same-name --perms --copy --marks --default
EOF
exit 0;
}

#TODO --same-name, --move?, --duplicates, --catalog

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
    # TODO zmodyfiowac
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
    esac
done
