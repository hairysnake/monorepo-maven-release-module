#!/bin/bash

# here define common libraries
libraries=("library-a" "library-b")

revert_version() {
    if [ -e "$1/pom.xml.versionsBackup" ]; then
        echo "reverting uncommited changes in $1"
        mvn versions:revert -pl $1
    fi
}

#
# revert uncommited changes (previous execution failed)
#

for folder in */; do
    module_name=${folder%/}
    revert_version $module_name
done

#
# get last tag from git
#

last_tag=$(git describe --tags --abbrev=0)

#
# build common libraries
#

for folder in */; do
    module_name=${folder%/}
    is_library=false

    for library in "${libraries[@]}"; do
        if [ "$module_name" == "$library" ]; then
            is_library=true
        fi
    done

    if [ $is_library == true ]; then
        commits=$(git log $last_tag..HEAD -- $module_name)
        if [ -n "$commits" ]; then    
            echo "$commits"
        fi
    fi
done

#
# build modules
#
for folder in */; do
    module_name=${folder%/}
    commits=$(git log $last_tag..HEAD -- $module_name)

    if [ -n "$commits" ]; then
        echo "changes"
    fi
done