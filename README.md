# X-Chat Azure

XChat Azure is a fork from X-Chat Aqua, the MacOSX native XChat front-end.

# Why has X-Chat Aqua been renamed?

Mac App Store is very useful place to distribute appliactions for non-geek users. Most of Debian/Ubuntu users do not want to search applications on broad Internet world, if you can access alternative applications on Aptitude. So Mac OS X users got the Mac App Store.

But I should keep Apple App Store guideline to submit X-Chat Aqua. There was some issues.

**Main Reason**: Any application on Mac App Store may not use names that include 'Mac', 'OS X', 'Aqua' or any other of Apples trade marks.

There was no way. So I dropped the name.
Also, where was several other issues because i didn't want to change X-Chat Aqua developement policy.

* We should remove whole ppc/ppc64 support
* We should remove update module (Sparkle, in this case)
* We should not work on ~/.xchat2 the traditional configutaion directory.

It should be annoying job to keep these on X-Chat Aqua.

# Move Aqua to Azure

If you are now using XChat GTK or X-Chat Aqua, and now you want to move to XChat Azure, you should do some work.

Unlike XChat GTK and X-Chat Aqua, XChat Azure do not share the traditional configuration direcotry ~/.xchat2 because of Appstore guideline.

So if you want to keep your configuration, you should move it, copy it, or make hard link.

* Step 1: Open Terminal.app to do this job. You can find it on Spotlight
* Step 2: Did you run XChat Azure already? Remove its configuration to do other job.
  * rm -rf ~/Library/Application\ Support/XChat\ Azure
* Move, if you will not user XChat GTK or X-Chat Aqua.
  * mv ~/.xchat2 ~/Library/Application\ Support/XChat\ Azure
* Copy, if you will use different configuration on Aqua and Azure, or you want to test Azure and back to original X-Chat Aqua.
  * cp -R ~/.xchat2 ~/Library/Application\ Support/XChat\ Azure
* Make hard link, if you want to share configurations.

OMG.. I don't know how to do. Do it yourself.

# For developers

Please visit http://github.com/youknowone/xchatazure
