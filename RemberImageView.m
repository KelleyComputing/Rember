#import "RemberImageView.h"

@implementation RemberImageView

- (void)mouseEntered:(NSEvent *)theEvent
{
	NSLog(@"Mouse entered image view with tag:");
}

- (void)mouseDown:(NSEvent *)theEvent
{
	NSLog(@"Mouse down on image view with tag: %i", [self tag]);
}

@end
