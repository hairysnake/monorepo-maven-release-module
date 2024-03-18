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
changed_modules=()

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
            snapshot_version=$(mvn --color never help:evaluate -Dexpression=project.version -q -DforceStdout -f $module_name)
            release_version=$(echo "$snapshot_version" | sed "s/-SNAPSHOT//" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")

            echo "$module_name current version $snapshot_version next release version $release_version"

            mvn versions:set -pl $module_name -DnewVersion=$release_version
            mvn clean install -pl $module_name
            mvn versions:commit
            find . -name pom.xml -exec git add {} \;
            git commit -m "$module_name version $release_version"

            changed_modules+=
        fi
    fi
done

echo "${changed_modules[@]}"

#
# build modules
#

for folder in */; do
    module_name=${folder%/}
    is_library=false
    commits=$(git log $last_tag..HEAD -- $module_name)

    for library in "${libraries[@]}"; do
        if [ "$module_name" == "$library" ]; then
            is_library=true
        fi
    done

    if [ $is_library == false ]; then
        commits=$(git log $last_tag..HEAD -- $module_name)

        if [ -n "$commits" ]; then
            snapshot_version=$(mvn --color never help:evaluate -Dexpression=project.version -q -DforceStdout -f $module_name)
            release_version=$(echo "$snapshot_version" | sed "s/-SNAPSHOT//" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")

            echo "$module_name current version $snapshot_version next release version $release_version"

            mvn versions:set -pl $module_name -DnewVersion=$release_version
            mvn clean package -pl $module_name
            mvn versions:commit
            git add $module_name/pom.xml
            git commit -m "$module_name version $release_version"
        fi
    fi
done