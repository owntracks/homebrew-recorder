# Recorder for Homebrew

```
brew tap owntracks/recorder
brew install recorder
  or
brew install recorder --with-lua
```

```
OwnTracks Recorder has been installed with a default configuration.
You can make changes to the configuration by editing and then
launching:
    /usr/local/etc/ot-recorder.sh
```

After installing version >= 0.4.1 please run this (it is non-destructive):

```
/usr/local/bin/ocat --load=luadb < /dev/null
/usr/local/bin/ocat --load=topic2tid < /dev/null
```
