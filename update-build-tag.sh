#!/bin/bash

last_tag=$(git describe --tags --abbrev=0)

for folder in */; do
    module_name=${folder%/}
    commits=$(git log $last_tag..HEAD -- $module_name)
    tag=

    if [ -n "$commits" ]; then
        echo "new commits in $module_name"
        echo -n "step 1 - current version evaluation ... "
        
        snapshot_version=$(mvn --color never help:evaluate -Dexpression=project.version -q -DforceStdout -f $module_name)
        echo "$snapshot_version"
        release_version=$(echo "$snapshot_version" | sed "s/-SNAPSHOT//" | sed -r "s/\x1B\[([0-9]{1,2}(;[0-9]{1,2})?)?[mGK]//g")

        echo "step 2 - releasing version $release_version for $module_name"
        echo ""
        mvn versions:set -pl $module_name -DnewVersion=$release_version
        
        echo ""
        echo "step 3 - building version $release_version for $module_name"
        echo ""
        mvn clean install -pl $module_name

        echo ""
        echo "step 4 - commit version $release_version for $module_name"
        echo ""
        git commit -m "$module_name version $release_version"
        
        new_snapshot_version="$release_version-SNAPSHOT"
        
        echo "step 4 - releasing new snapshot version $new_snapshot_version for $module_name"
        echo ""
        mvn versions:set -pl $module_name -DnewVersion=$new_snapshot_version
    fi
done