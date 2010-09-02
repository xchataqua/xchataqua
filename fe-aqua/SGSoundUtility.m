#import "SGSoundUtility.h"

@implementation SGSoundUtility

+ (NSArray *) systemSounds
{
	NSMutableArray *paths = [[NSMutableArray alloc] init];
	
	NSArray *directories = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSAllDomainsMask, YES);
															 
	for ( NSString *libraryName in directories )
	{
		NSString *directoryName = [NSString stringWithFormat:@"%@/Sounds", libraryName];
		NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directoryName error:NULL];
		
		for ( NSString *file in files )
		{
			NSString *path = [directoryName stringByAppendingFormat:@"/%@", file];
			[paths addObject:path];
		}
	}

	return paths;
}

@end