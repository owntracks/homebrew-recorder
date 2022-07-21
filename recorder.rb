class Recorder < Formula
  desc "Store and access location data published via MQTT from OwnTracks apps"
  homepage "http://owntracks.org"
  url "https://github.com/owntracks/recorder/archive/0.9.0.tar.gz"
  version "0.9.0"
  sha256 "a9d80bb5154f1846074244cd3d0de4e93d109de98b8f7985f4b6a13a5f6b330a"

  option "with-lua", "Add support for Lua filtering"

  def withlua
      if build.with?("lua")
	"yes"
      else
	"no"
      end
  end


  # Recorder requires Mosquitto headers/libs for building
  depends_on "mosquitto"
  depends_on "lmdb"
  depends_on "lua" => [:optional, "lua"]
  depends_on "libconfig"

  def pre_install
    if (etc+"ot-recorder.sh").exist?
       (etc+"ot-recorder.sh").copy("/tmp/ot-recorder.sh")
       ohai "Existing ot-recorder.sh has been copied to /tmp"
    end
  end

  def install

    if (etc+"ot-recorder.sh").exist?
       copy(etc+"ot-recorder.sh", "/tmp/ot-recorder.sh.backup")
       ohai "Existing ot-recorder.sh has been copied to /tmp/ot-recorder.sh.backup"
    end

    ENV.deparallelize  # if your formula fails when building in parallel

    # Create our config.mk from scratch
    (buildpath+"config.mk").write config_mk

    system "make"
    # system "make", "install", "DESTDIR=#{prefix}"

    # Create the working directories
    (var/"owntracks").mkpath
    (var/"owntracks/recorder").mkpath
    (var/"owntracks/recorder/htdocs").mkpath
    (var/"owntracks/recorder/store").mkpath
    (var/"owntracks/recorder/store/last").mkpath
    (var/"owntracks/recorder/store/ghash").mkpath
    (var/"owntracks/recorder/store/rec").mkpath

    sbin.install "ot-recorder"
    chmod 0755, sbin/"ot-recorder"

    bin.install "ocat"
    chmod 0755, bin/"ocat"

    doc.install "README.md"

    # (var/"owntracks/recorder/htdocs").install Dir["docroot/*"]

    # install htdocs/docroot. This will create a symlink to
    # /usr/local/share/recorder/docroot
    pkgshare.install Dir["docroot"]
    pkgshare.install "contrib"

  end

  def post_install
      unless (etc+"ot-recorder.sh").exist?
         # Create Recorder launch script with configuration in it
         (etc+"ot-recorder.sh").write launch_script
         chmod 0755, etc/"ot-recorder.sh"
      end
      # ohai "initializing topic2tid" + %x("#{bin}/ocat" --load=topic2tid < /dev/null)

      ohai "checking whether lmdb needs initializing"
      system "#{sbin}/ot-recorder", "--initialize"
  end

  test do
     system "#{bin}/ocat", "--version"
  end

  def caveats; <<-EOD
    OwnTracks Recorder has been installed with a default configuration.
    You can make changes to the configuration by editing and then
    launching:
        #{etc}/ot-recorder.sh
    EOD
  end

  def config_mk; <<-EOS
      INSTALLDIR = /
      CONFIGFILE = #{etc}/default/ot-recorder
      WITH_MQTT ?= yes
      WITH_HTTP ?= yes
      WITH_LUA ?= #{withlua}
      WITH_PING ?= yes
      WITH_KILL ?= no
      WITH_ENCRYPT ?= no
      WITH_GREENWICH ?= yes
      STORAGEDEFAULT = #{var}/owntracks/recorder/store
      DOCROOT = #{share}/recorder/docroot
      GHASHPREC = 7
      JSON_INDENT ?= no
      APIKEY ?=
      MOSQUITTO_INC = -I#{include}
      MOSQUITTO_LIB = -L#{lib}
      MORELIBS = # -lssl
      LUA_CFLAGS = -I#{include}
      LUA_LIBS   = -L#{lib} -llua -lm
      GEOCODE_TIMEOUT = 4000
    EOS
  end

  def launch_script; <<-EOS
    #!/bin/sh
    # Launch script for OwnTracks Recorder

    #: Configuration for Private mode (your own MQTT broker). This requires
    #: at least HOST and PORT. If you need TLS, set CAFILE, and for
    #: authentication set USER and PASS additionally.

    #:-- Private mode
    export OTR_HOST="127.0.0.1"		# MQTT hostname
    export OTR_PORT="1883"		# MQTT port (set to 8883 for TLS and define OTR_CAFILE)
    #export OTR_USER=""			# broker user name
    #export OTR_PASS=""			# broker password
    #export OTR_CAFILE=""		# PEM CA certificate chain for broker

    opts="${opts} --http-host 127.0.0.1 --http-port 8083"

    exec "#{sbin}/ot-recorder" ${opts} "owntracks/#"
    EOS
  end

  test do
    # `test do` will create, run in and delete a temporary directory.
    #
    # This test will fail and we won't accept that! It's enough to just replace
    # "false" with the main program this formula installs, but it'd be nice if you
    # were more thorough. Run the test with `brew test recorder`. Options passed
    # to `brew install` such as `--HEAD` also need to be provided to `brew test`.
    #
    # The installed folder is not in the path, so use the entire path to any
    # executables being tested: `system "#{bin}/program", "do", "something"`.
    system "false"
  end


  plist_options :manual => "#{HOMEBREW_PREFIX}/etc/ot-recorder.sh"

  def plist; <<-EOS
    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
    <dict>
      <key>Label</key>
      <string>#{plist_name}</string>
      <key>ProgramArguments</key>
      <array>
        <string>#{etc}/ot-recorder.sh</string>
      </array>
      <key>RunAtLoad</key>
      <true/>
      <key>KeepAlive</key>
      <false/>
      <key>WorkingDirectory</key>
      <string>#{var}/owntracks</string>
    </dict>
    </plist>
    EOS
  end

end
