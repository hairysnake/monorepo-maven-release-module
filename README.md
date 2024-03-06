# monorepo-maven-release-module
This is test repository for checking the solution for changed module deployment.


-- create tag from timestamp
> git tag v$(date +'%Y%m%d%H%M%S')

-- current module version
> mvn help:evaluate -Dexpression=project.version -q -DforceStdout -f service-a

