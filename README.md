# X-Chat Azure

XChat Azure is a fork from X-Chat Aqua, the Mac OS X native XChat front-end.

# Why has X-Chat Aqua been renamed?

Mac App Store is very useful place to distribute applications for non-geek users. Most of Debian/Ubuntu users do not want to search applications on broad Internet world, if you can access alternative (or even the same) applications on Aptitude. So Mac OS X users got the Mac App Store.

But I should keep Mac App Store guidelines to submit X-Chat Aqua. There were some issues.

**Main Reason**: Any application on Mac App Store may not use names that include 'Mac', 'OS X', 'Aqua' or any other of Apples trademarks.

There was no way. So I dropped the name.
Also, where was several other issues because I didn't want to change X-Chat Aqua developement policy.

* We should remove whole ppc/ppc64 support
* We should remove update module (Sparkle, in this case)
* We should not work on ~/.xchat2 the traditional configutaion directory.

It should be annoying job to keep these on X-Chat Aqua.

# Move Aqua to Azure

If you are now using XChat GTK or X-Chat Aqua, and now you want to move to XChat Azure, you should do some work.

Unlike XChat GTK and X-Chat Aqua, XChat Azure do not share the traditional configuration direcotry ~/.xchat2 because of Mac App Store guideline.

So if you want to keep your configuration, you should move it, copy it, or make hard link.

1. Open Terminal.app to do this job. You can find it on Spotlight
2. Did you run XChat Azure already? Remove its configuration to do other job
  * rm -rf ~/Library/Application\ Support/XChat\ Azure
3. Move, if you will not use XChat GTK or X-Chat Aqua again
  * mv ~/.xchat2 ~/Library/Application\ Support/XChat\ Azure
4. Copy, if you will use different configuration on Aqua and Azure, or you want to test Azure and get back to original X-Chat Aqua.
  * cp -R ~/.xchat2 ~/Library/Application\ Support/XChat\ Azure
5. Hard-/Soft-Link, if you want to share configurations
  * ln ~/.xchat2 ~/Library/Application\ Support/XChat\ Azure

OMG.. I don't know how to do. Do it yourself.

# For developers

Please visit http://github.com/youknowone/xchatazure
