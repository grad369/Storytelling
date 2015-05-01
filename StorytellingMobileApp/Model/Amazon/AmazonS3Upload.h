//

#import <Foundation/Foundation.h>

@class Story;

typedef void(^EmptyBlock)();

@interface AmazonS3Upload : NSOperation
@property (nonatomic, copy) void(^progressBlock)(float progress);

- (instancetype)initWithStory:(Story*)story;
- (NSURL*)shareURL;
@end
