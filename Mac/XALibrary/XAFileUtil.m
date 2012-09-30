//
//  XAFileUtil.m
//
//  Created by Terje Bless on 2012-09-03.
//  Based on SGFileUtility by Steve Green.
//
//

//
// Utility class to handle various generic file-related operations
//
// XAFileUtil has only class methods and in practice cannot be subclassed or
// instantiated (but there is no code to prevent a client from trying).
//
// The methods are relatively generic, but have been implemented specifically
// to address the needs of XChat Azure (and Aqua). In particular, the utility
// methods (exists:, isDirectory:, etc.) only cover the checks XCA needs, and
// the creation methods (createSupportDirectory:, etc.) only cover the
// directories XCA needs. No attempt has been made to cover the full API that
// NSFileManager provides, and method signatures and return types are
// optimized for the calling contexts within XCA. Use NSFileManager directly
// if you need anything more than what's provided here.
//
// Mostly these methods are called from initialization code dealing with the
// main Application Support directory (fe-aqua.m:setupAppSupport:), or similar
// for plugin initialization (fe-aqua.m:init_plugins_once:), but there's
// quite a bit of code that calls findSupportDirectoryFor: to get at the app
// support directory or one of its subdirectories scattered around.
//
// The main point of the class is to hide complexity like path vs. URL based
// API (the latter of which is only available from Mac OS X >= 10.7) and the
// file property checks (where we only need a BOOLean and don't care about the
// full set of capabilities NSFileManager provides). Thus it has no dependencies
// on other parts of SGLib/XALibrary, and its implementation details are mostly
// completely opaque to client code (i.e. implementation can be safely changed
// so long as method signature and return type is maintained).
//


#import "XAFileUtil.h"

@implementation XAFileUtil

#pragma mark -
#pragma mark Utility functions for BOOLean checks of file/dir properties


// Checks if a given file or directory exists and returns YES/NO accordingly
//
// Note that this will traverse symlinks and return based on the *target* of
// the symlink, and not on the symlink itself.
+ (BOOL) exists:(NSURL *) url {
    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:NULL];
    return result;
}

// Checks whether a given path is a directory and returns YES/NO accordingly
//
// Note that this will traverse symlinks and return based on the *target* of
// the symlink, and not on the symlink itself.
+ (BOOL) isDirectory:(NSURL *) url {
    BOOL isDir;

    BOOL result = [[NSFileManager defaultManager] fileExistsAtPath:[url path] isDirectory:&isDir];

    if (result == YES) {
        return isDir; // It exists, and isDir tells us whether it is a directory
    } else {
        return NO; // It doesn't exist or there was an error
    }
}

// Checks whether a given path is a symlink and returns YES/NO accordingly
//
// This will obviously NOT traverse the symlink as that's the property we're
// interested in.
+ (BOOL) isSymLink:(NSURL *) url {
    BOOL isSymlink;

    NSDictionary *attrs =
        [[NSFileManager defaultManager] attributesOfItemAtPath:[url path] error:nil];

    if ([attrs objectForKey:NSFileType] == NSFileTypeSymbolicLink) {
        isSymlink = YES;
    } else {
        isSymlink = NO;
    }

    return isSymlink;
}

#pragma mark -
#pragma mark Locate Application Support folders

//
// Locates the Application Support folder for the named application
//
// The top level Application Support folder will vary depending on whether we're
// running Sandboxed or not; and the OS only tells you the container: you have
// to supply the name of your application's specific subdirectory yourself.
//
// Will typically return an NSURL object pointing at
//   ~/Library/Application Support/XChat Aqua/
// ...or...
//   ~/Library/Containers/org.3rddev.xchatazure/Data/Library/Application Support/XChat Azure/
// ...depending on variant.
//
+ (NSURL *) findSupportFolderFor:(NSString *) appName {
    NSFileManager *manager = [NSFileManager defaultManager];

    NSURL *AppSupport = [manager URLForDirectory:NSApplicationSupportDirectory
                                        inDomain:NSUserDomainMask
                               appropriateForURL:nil create:NO error:nil];
    NSURL *XCAppSupport = [AppSupport URLByAppendingPathComponent:appName];

    return XCAppSupport;
}

//
// Locates a specific folder within the Application Support folder
//
// Calls back to findSupportFolderFor: to find our application's top level
// folder, and returns an URL to a folder within that folder. Typically this
// will be something like: ~/Library/Application Support/XChat Aqua/plugins/
//
+ (NSURL *) findSupportFolderFor:(NSString *) appName named:(NSString *) folder {
    NSURL *XCAppSupport = [XAFileUtil findSupportFolderFor:appName];
    NSURL *XCSupportFolder = [XCAppSupport URLByAppendingPathComponent:folder];

    return XCSupportFolder;
}


#pragma mark -
#pragma mark Create Application Support folders

//
// Create the appropriate Application Support directory for the given app name
//
// Returns only YES/NO to indicate success or failure since this is an
// unrecoverable error. Returns NSFileManager's NSError object in the passed in
// err object pointer.
//
+ (BOOL) createSupportFolderFor:(NSString *) appName error:(NSError **)err  {
    NSURL *XCAppSupport = [XAFileUtil findSupportFolderFor:appName];

    NSFileManager *manager = [NSFileManager defaultManager];

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_7
    // If Deployment Target is 10.7 or newer, use createDirectoryAtURL:...
    BOOL result = [manager createDirectoryAtURL:XCAppSupport
               withIntermediateDirectories:YES attributes:nil error:err];
#else
    // ...otherwise convert to a path and use createDirectoryAtPath:.
    BOOL result = [manager createDirectoryAtPath:[XCAppSupport path]
                withIntermediateDirectories:YES attributes:nil error:err];
#endif

    // createDirectoryAt<Path|URL>: returns YES if the directory was created or
    // if it already existed, and NO if it did not exist and could not be created,
    // provided withIntermediateDirectories: is YES (if it's NO then this method
    // will also return NO when the directory specified already exists).
    return result;
}

//
// Create the named Support folder, within App Support, for the given app name
//
// Returns only YES/NO to indicate success or failure since this is an
// unrecoverable error. Returns NSFileManager's NSError object in the passed in
// err object pointer.
//
+ (BOOL) createSupportFolderFor:(NSString *) appName named:(NSString *) folder error:(NSError **)err {
    NSURL *XCAppSupport = [XAFileUtil findSupportFolderFor:appName];
    NSURL *XCSupportFolder = [XCAppSupport URLByAppendingPathComponent:folder];

    NSFileManager *manager = [NSFileManager defaultManager];

#if MAC_OS_X_VERSION_MIN_REQUIRED >= MAC_OS_X_VERSION_10_7
    // If Deployment Target is 10.7 or newer, use createDirectoryAtURL:...
    BOOL result = [manager createDirectoryAtURL:XCSupportFolder
               withIntermediateDirectories:YES attributes:nil error:err];
#else
    // ...otherwise convert to a path and use createDirectoryAtPath:.
    BOOL result = [manager createDirectoryAtPath:[XCSupportFolder path]
                withIntermediateDirectories:YES attributes:nil error:err];
#endif

    // createDirectoryAt<Path|URL>: returns YES if the directory was created or
    // if it already existed, and NO if it did not exist and could not be created,
    // provided withIntermediateDirectories: is YES (if it's NO then this method
    // will also return NO when the directory specified already exists).
    return result;
}


@end
