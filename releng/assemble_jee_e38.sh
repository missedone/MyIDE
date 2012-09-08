#!/bin/sh

JAVA_HOME=/usr/java/default/
ees_dir=/opt/ees
build_dir=$ees_dir/build
p2_builder_dir=$ees_dir/builder/eclipse

ees_name="eclipse-jee-3.8"

p2_repo_url="file:/opt/MyEclipse/updatesite"
target_platform_dir=$build_dir/target-platform

source_platform_archive=$1
p2_target_profile=PlatformProfile
p2_target_installIU="jp.gr.java_conf.ussiy.app.propedit.feature.group/6.0.0,org.eclipse.egit.feature.group,org.eclipse.egit.import.feature.group,org.eclipse.egit.mylyn.feature.group,org.eclipse.egit.psf.feature.group,org.eclipse.jdt.feature.group,org.eclipse.jgit.feature.group,org.eclipse.jst.server_adapters.ext.feature.feature.group,org.eclipse.jst.server_adapters.feature.feature.group,org.eclipse.jst.server_core.feature.feature.group,org.eclipse.jst.server_ui.feature.feature.group,org.eclipse.m2e.feature.feature.group,org.eclipse.m2e.wtp.feature.feature.group,org.eclipse.mylyn.builds.feature.group,org.eclipse.mylyn.git.feature.group,org.eclipse.mylyn.hudson.feature.group,org.eclipse.mylyn.ide_feature.feature.group,org.eclipse.mylyn.java_feature.feature.group,org.eclipse.mylyn.tasks.ide.feature.group,org.eclipse.mylyn.team_feature.feature.group,org.eclipse.mylyn.versions.feature.group,org.eclipse.mylyn_feature.feature.group,org.eclipse.wst.server_adapters.feature.feature.group,org.eclipse.wst.server_core.feature.feature.group,org.eclipse.wst.server_ui.feature.feature.group,org.eclipse.wst.xml_core.feature.feature.group,org.eclipse.wst.xml_ui.feature.feature.group,org.eclipse.wst.xsl.feature.feature.group,org.testng.eclipse.feature.group,AnyEditTools.feature.group,com.googlecode.eclipse.navigatorext.features.feature.group"

#######################################
# function definition
#######################################
assemble() {

  source_platform_archive=$1
  p2_target_profile=$2
  p2_target_installIU=$3

  p2_target=$target_platform_dir/$ees_name
  build_time=`date +%Y%m%d_%H%M`

  echo "#####################################################"
  echo "Using:       vm=$JAVA_HOME/bin/java";
  echo "Source platform archive: $source_platform_archive";
  echo "Source JRE archive: $source_jre_archive";
  echo "P2 Profile: $p2_target_profile";
  echo "#####################################################"

  echo "### pre install"
  mkdir -p $build_dir
  rm -rf $target_platform_dir
  mkdir -p $target_platform_dir

  echo "#### extract the source platform archive: $source_platform_archive"
  if [[ "$source_platform_archive" == *.tar.gz ]];
  then
    tar xf $source_platform_archive --directory=$target_platform_dir
  else
    unzip -q $source_platform_archive -d $target_platform_dir
  fi
  mv $target_platform_dir/eclipse $p2_target

  if [[ "$source_platform_archive" == *-linux*.* ]];
  then
    p2_target_os=linux
  else
    p2_target_os=win32
  fi

  if [[ "$source_platform_archive" == *x86_64*.* ]];
  then
    p2_target_arch=x86_64
  else
    p2_target_arch=x86
  fi

  echo "### install the plugins"
  $p2_builder_dir/eclipse -vm $JAVA_HOME/bin/java -nosplash --launcher.suppressErrors -consoleLog \
    -application org.eclipse.equinox.p2.director \
    -roaming \
    -profile ${p2_target_profile} \
    -destination ${p2_target} \
    -bundlepool ${p2_target} \
    -installIU $p2_target_installIU \
    -metadataRepository ${p2_repo_url},file:${p2_target}/p2/org.eclipse.equinox.p2.engine/profileRegistry/${p2_target_profile}.profile \
    -artifactRepository ${p2_repo_url},file:${p2_target} \
    -repository ${p2_repo_url} \
    -profileProperties org.eclipse.update.install.features=true \
    -p2.os ${p2_target_os} \
    -p2.arch ${p2_target_arch}
  if [ $? != 0 ] ; then
    echo "installed plugins failed"
    exit 1;
  fi

  echo "### post install"

  if [ -f ./plugin_customization_e38.ini ]; then
    plugin_customization=`find ${p2_target} -name plugin_customization.ini -print | grep 'org.eclipse'`
    echo "#### append web proxies settings to $plugin_customization"
    cat ./plugin_customization_e38.ini >> $plugin_customization
  fi

  ees_archive_name=${ees_name}-${build_time}-${p2_target_os}-${p2_target_arch}

  pushd `pwd` >/dev/null
  cd $target_platform_dir
  echo "##### package to ${ees_archive_name}"
  if [[ "$source_platform_archive" == *.tar.gz ]]; then
    tar -zcf ${build_dir}/${ees_archive_name}.tar.gz ./
  else
    zip -q -r ${build_dir}/${ees_archive_name}.zip ./
  fi
  popd >/dev/null

  echo "build complete successfully"
}  

source_platform_archive=/opt/ees/binaries/eclipse-platform-3.8-M20120905-1000-win32.zip
assemble $source_platform_archive $p2_target_profile $p2_target_installIU
