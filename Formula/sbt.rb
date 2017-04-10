class Sbt < Formula
  desc "Build tool for Scala projects"
  homepage "http://www.scala-sbt.org"
  url "https://dl.bintray.com/sbt/native-packages/sbt/0.13.15/sbt-0.13.15.tgz"
  sha256 "b6e073d7c201741dcca92cfdd1dd3cd76c42a47dc9d8c8ead8df7117deed7aef"

  devel do
    url "https://dl.bintray.com/sbt/native-packages/sbt/1.0.0-M4/sbt-1.0.0-M4.tgz"
    sha256 "8cb2eaabcbfeceeb65023311b08c980feff80552b22524213c71857ced2f8de7"
    version "1.0.0-M4"
  end

  bottle :unneeded

  depends_on :java => "1.6+"

  def install
    inreplace "bin/sbt" do |s|
      s.gsub! 'etc_sbt_opts_file="${sbt_home}/conf/sbtopts"', "etc_sbt_opts_file=\"#{etc}/sbtopts\""
      s.gsub! "/etc/sbt/sbtopts", "#{etc}/sbtopts"
    end

    inreplace "bin/sbt-launch-lib.bash" do |s|
      s.gsub! "${sbt_home}/bin/sbt-launch.jar", "#{libexec}/sbt-launch.jar"
      if s.include?("${sbt_bin_dir}/java9-rt-export.jar")
        s.gsub! "${sbt_bin_dir}/java9-rt-export.jar", "#{libexec}/java9-rt-export.jar"
      end

      if s.include?("$sbt_home/lib/local-preloaded/")
        s.gsub! "$sbt_home/lib/local-preloaded/", "#{libexec}/lib/local-preloaded/"
      end

      ## This is required to pass the test
      if s.include?("[[ \"$java_version\" > \"8\" ]]")
        s.gsub! "[[ \"$java_version\" > \"8\" ]]", "[[ \"$java_version\" == \"9\" ]]"
      end
    end

    libexec.install "bin/sbt", "bin/sbt-launch-lib.bash"
    libexec.install Dir["bin/*.jar"]
    etc.install "conf/sbtopts"

    if File.directory?("lib")
      libexec.install "lib"
    end

    (bin/"sbt").write <<-EOS.undent
      #!/bin/sh
      if [ -f "$HOME/.sbtconfig" ]; then
        echo "Use of ~/.sbtconfig is deprecated, please migrate global settings to #{etc}/sbtopts" >&2
        . "$HOME/.sbtconfig"
      fi
      exec "#{libexec}/sbt" "$@"
    EOS
  end

  def caveats;  <<-EOS.undent
    You can use $SBT_OPTS to pass additional JVM options to SBT:
       SBT_OPTS="-XX:+CMSClassUnloadingEnabled -XX:MaxPermSize=256M"

    This formula is now using the standard lightbend sbt launcher script.
    Project specific options should be placed in .sbtopts in the root of your project.
    Global settings should be placed in #{etc}/sbtopts
    EOS
  end

  test do
    ENV["_JAVA_OPTIONS"] = "-Dsbt.log.noformat=true"
    ENV.java_cache
    output = shell_output("#{bin}/sbt sbt-version")
    assert_match "[info] #{version}", output
  end
end
