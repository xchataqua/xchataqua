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

# Move GTK xchat2 or XChat Aqua to Azure

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

# I lost all configurations after update to 1.11 or later

After Azure 1.11, it is using App sandboxing by Apple Appstore policy.

In most of case, this is occured because your Azure configuration directory is symlink to other one.

To recover this, follow these step.

1. Quit Azure
2. Remove all the configurations from sandbox container
  * rm -rf ~/Library/Containers/org.3rddev.xchatazure
3. Find your original configuration
  1. Open Terminal.app to do this job. You can find it on Spotlight.
    * open -a Finder ~/Library/Application\ Support
  2. if 'X-Chat Aqua' exists and not a symlink (aka shortcut), rename it to 'XChat Azure'
  3. if not, go ahead...
    * ls -l -a ~ | grep xchat
  4. if you don't see '.xchat2 -> ...', it is the original one. run next.
    * mv ~/.xchat2 ~/Library/Application\ Support/XChat\ Azure
  5. Not resolved yet? Report please.