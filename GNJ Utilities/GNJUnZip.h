//
//  GNJUnZip.h
//  GNJUnZip
//
//  Created by Genji on 2015/03/03.
//
//

#import <Foundation/Foundation.h>

@interface GNJUnZip : NSObject

/** The path of the zip file. */
@property (nonatomic, readonly, copy) NSString *path;

/** The items contained in the zip file. The array of `NSString` objects. */
@property (nonatomic, readonly) NSArray *items;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)initWithZipFile:(NSString *)path NS_DESIGNATED_INITIALIZER;
- (NSData *)dataWithContentsOfFile:(NSString *)path;

@end
