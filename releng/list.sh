#!/bin/sh

JAVA_HOME=/usr/java/default/
ees_dir=/opt/ees
p2_builder_dir=$ees_dir/builder/eclipse
if test "x$1" = "x"; then
  p2_repo_url="file:/opt/ees/myupdatesite/"
else
  p2_repo_url=$1
fi

$p2_builder_dir/eclipse -vm $JAVA_HOME/bin/java -nosplash --launcher.suppressErrors -consoleLog \
  -application org.eclipse.equinox.p2.director \
  -repository ${p2_repo_url} \
  -list

