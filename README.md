# X-Chat Aqua

X-Chat Aqua is a XChat front-end for Mac OS X. It originally starts from http://sourceforge.net/projects/xchataqua/

# XChat Azure

XChat Azure is a fork from X-Chat Aqua, the Mac OS X native XChat front-end.

# Why has X-Chat Aqua been renamed?

Mac App Store is very useful place to distribute applications for non-geek users. Most of Debian/Ubuntu users do not want to search applications on broad Internet world, if you can access alternative (or even the same) applications on Aptitude. So Mac OS X users got the Mac App Store.

But I should keep Mac App Store guidelines to submit X-Chat Aqua. There were some issues.

**Main Reason**: Any application on Mac App Store may not use names that include 'Mac', 'OS X', 'Aqua' or any other of Apples trademarks.

There was no way. So I dropped the name.
Also, where was several other issues because I didn't want to change X-Chat Aqua developement policy.

* We should remove whole ppc/ppc64 support
* We should support osx10.6 only
* We should remove update module (Sparkle, in this case)
* We should not work on ~/.xchat2 the traditional configutaion directory.

It should be annoying job to keep these on X-Chat Aqua.

# I lost all configurations after update to 1.11 or later

* Your configuration has gone?
* Your configuration is not saved when you quit the application?

## Auto-recovery script
  0. WARNING: DO NOT RUN THIS SCRIPT WHILE RUNNING XCHAT AZURE
  1. Download the [Script](http://xchataqua.github.com/downloads/fixdata.tar)
  2. Run the script: It will show the result. No bad message mean Good result.

## For profesional

After Azure 1.11, it is using App sandboxing by Apple Appstore policy.

In most of case, this is occured because your Azure configuration directory is symlink to other one.

To recover this, find the original configuration and replace symlink to original one.

1. Quit Azure
2. Remove all the configurations from sandbox container
  * rm -rf ~/Library/Containers/org.3rddev.xchatazure
3. Find your original configuration. Candidates are:
  1. ~/.xchat2 (If you moved from ancient Aqua or GTK)
  2. ~/Library/Application Support/X-Chat Aqua (If you moved from Aqua)
  3. ~/Library/Application Support/XChat Azure (If something goes wrong with Azure)

# Move GTK xchat2 or XChat Aqua to Azure

NOTE: DO NOT TRY THIS IF YOU DON'T UNDERSTAND WHAT YOU ARE DOING

If you are now using XChat GTK or X-Chat Aqua, and now you want to move to XChat Azure, you should do some work.

Unlike XChat GTK and X-Chat Aqua, XChat Azure do not share the traditional configuration direcotry ~/.xchat2 because of Mac App Store guideline.

So if you want to keep your configuration, you should move it, copy it, or make hard link.

1. Quit Azure
2. Open Terminal.app to do this job. You can find it on Spotlight.
3. Did you run XChat Azure already? Remove its configuration to do other job
  * rm -rf ~/Library/Containers/org.3rddev.xchatazure
4. Move, if you will not use XChat GTK or X-Chat Aqua again
  * For GTK: mv ~/.xchat2 ~/Library/Application\ Support/XChat\ Azure
  * For Aqua: mv ~/Library/Application\ Support/X-Chat\ Aqua ~/Library/Application\ Support/XChat\ Azure
5. Copy, if you will use different configuration on Aqua and Azure, or you want to test Azure and get back to original X-Chat Aqua.
  * For GTK: cp -R ~/.xchat2 ~/Library/Application\ Support/XChat\ Azure
  * For Aqua: cp -R ~/Library/Application\ Support/X-Chat\ Aqua ~/Library/Application\ Support/XChat\ Azure
