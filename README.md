[![Build Status](https://travis-ci.org/xchataqua/xchataqua.svg?branch=master)](https://travis-ci.org/xchataqua/xchataqua)

# X-Chat Aqua

X-Chat Aqua is a XChat front-end for Mac OS X.
Visit us [http://xchataqua.github.io/](http://xchataqua.github.io/) (Moved from [http://sourceforge.net/projects/xchataqua/](http://sourceforge.net/projects/xchataqua/))

# XChat Azure

XChat Azure is a new brand of X-Chat Aqua, especially for Apple Appstore. See below for details.

# Downloads
* 10.7/10.8: Official appstore release is working on latest 2 versions of OS X. Download it from [Appstore](http://itunes.apple.com/app/id447521961)
* For older OS X versions or development version, visit [http://xchataqua.github.io/#Download](http://xchataqua.github.io/#Download)


# I lost all configurations after update to 1.11 or later

* Your configuration has gone?
* Your configuration is not saved when you quit the application?

## Auto-recovery script
  0. WARNING: DO NOT RUN THIS SCRIPT WHILE RUNNING XCHAT AZURE
  1. Download the [Script](http://xchataqua.github.io/downloads/fixdata.tar)
  2. Run the script: It will show the result. No bad message means Good result.

## For profesional

After Azure 1.11, it is using App sandboxing by Mac Appstore policy.

In most of case, this is occured because your Azure configuration directory is symlink to other one.

To recover this, find the original configuration and replace symlink to original one.

1. Quit Azure
2. Remove all the configurations from sandbox container
  * rm -rf ~/Library/Containers/org.3rddev.xchatazure
3. Find your original configuration. Candidates are:
  1. ~/.xchat2 (If you moved from ancient Aqua or GTK)
  2. ~/Library/Application Support/X-Chat Aqua (If you moved from Aqua)
  3. ~/Library/Application Support/XChat Azure (If something goes wrong with Azure)

# Where is my config files? Where is my log files?

Look in

> \~/Library/Containers/org.3rddev.xchatazure/Data/Library/Application Support/XChat Azure/

Where "~" means your home directory. (For example, /Users/myname.)

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

# Why has X-Chat Aqua been renamed?

Mac App Store is very useful place to distribute applications for non-geek users. Most of Debian/Ubuntu users do not want to search applications on broad Internet world, if you can access alternative (or even the same) applications on Aptitude. So Mac OS X users got the Mac App Store.

But I should keep Mac App Store guidelines to submit X-Chat Aqua. There were some issues.

**Main Reason**: Any application on Mac App Store may not use names that include 'Mac', 'OS X', 'Aqua' or any other of Apples trademarks.

There was no way. So I dropped the name.
Also, there was several other issues because I didn't want to change X-Chat Aqua developement policy.

* We should remove whole ppc/ppc64 support
* We should support only OS X 10.6 or later
* We should remove update module (Sparkle, in this case)
* We should not work on ~/.xchat2 the traditional configutaion directory.

It should be annoying job to keep these on X-Chat Aqua.

