//
//  ApplicationEntry.h
//

#import <Cocoa/Cocoa.h>


@interface ApplicationEntry : NSObject 
{
	NSString* name;
	NSString* path;
	NSImage* icon;
}
@property (copy) NSString* name;
@property (copy) NSString* path;
@property (retain) NSImage* icon;

-(id)initWithPath:(NSString*)aPath;

@end
