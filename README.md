# File Management Script (asu.sh)

## Overview
This project provides a Bash script (`asu.sh`) to help manage files and directories by performing various operations such as removing duplicates, renaming files, copying or moving files to specified directories, and more. It is designed to clean up file systems by applying multiple operations specified by the user.

The script is customizable, supports multiple catalogs, and allows various actions to be performed on files within those catalogs. It can replace problematic characters in filenames, manage file permissions, and even handle temporary files.

**Note:** This project was developed as part of my university studies.

## Features
- **Remove duplicates:** Identify and remove duplicate files, keeping the oldest version.
- **Rename files:** Rename files within given directories interactively.
- **Copy/move files:** Copy or move files to a specified directory.
- **Remove empty files and directories:** Clean up empty files or entire directories.
- **Change file permissions:** Modify file permissions to a default specified value.
- **Handle temporary files:** Remove temporary files based on predefined patterns.
- **Replace problematic characters:** Rename files containing problematic characters, replacing them with safe alternatives.
  
## Usage
```bash
./asu.sh [CATALOGS] [OPTIONS]
```

Options:\
-h, --help : Display this help message.\
-x, --catalog [DIRECTORY] : Specify the main directory for copy or move operations.\
-d, --duplicates : Remove duplicate files, keeping the oldest.\
-e, --empty : Remove empty files.\
-l, --empty-dir : Remove empty directories and subdirectories.\
-t, --temp : Remove temporary files.\
-c, --copy : Copy files to the directory specified by the -x|--catalog option.\
-v, --move : Move files to the directory specified by the -x|--catalog option.\
-r, --rename : Rename files in the given directories.\
-s, --same-name : Remove files with the same name, keeping the oldest.\
-p, --perms : Change file permissions to the default value.\
-m, --marks : Replace problematic characters in filenames.

Example Usage:
```bash
./asu.sh ./X ./Y1 ./Y2 ./Y3 --catalog ./X --duplicates --empty --temp --same-name --perms --copy --marks
```
