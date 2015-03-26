//
//  GNJUnZip.m
//  GNJUnZip
//
//  Created by Genji on 2015/03/03.
//
//

#import "GNJUnZip.h"
#import "minizip/unzip.h"
#import "GNJUtilities.h"

@interface GNJUnZip ()

@property (nonatomic, readwrite, copy) NSString *path;
@property (nonatomic) unzFile unzip;
@property (nonatomic, strong) NSCache *cache;

@end

@implementation GNJUnZip

- (instancetype)initWithZipFile:(NSString *)path
{
  self = [super init];
  if(self) {
    self.unzip = unzOpen(path.fileSystemRepresentation);
    if(!self.unzip) {
      NSLog(@"error: cannot open the zip file specified by path '%@'.", path);
      return nil;
    }
    self.path = path;
    self.cache = [[NSCache alloc] init];
    self.cache.countLimit = 20;
  }

  return self;
}

- (void)dealloc
{
  if(self.unzip) {
    unzClose(self.unzip);
  }
}


#pragma mark -
#pragma mark Accessor Method
- (NSArray *)items
{
  if(!self.unzip) {
    NSLog(@"error: the zip file is not opened yet.");
    return nil;
  }

  if(unzGoToFirstFile(self.unzip) != UNZ_OK) {
    NSLog(@"error: cannot go to first file in the zip file.");
    return nil;
  }

  NSMutableArray *items = [NSMutableArray array];
  do {
    char rawFilePath[1024];
    unz_file_info fileInfo;
    if(unzGetCurrentFileInfo(self.unzip, &fileInfo, rawFilePath, sizeof(rawFilePath), NULL, 0, NULL, 0) != UNZ_OK) {
      NSLog(@"error: cannot get current file info.");
      continue;
    }
    NSString *filePath = [NSString stringWithCString:rawFilePath encoding:NSUTF8StringEncoding];
    [items addObject:filePath];
  }
  while(unzGoToNextFile(self.unzip) != UNZ_END_OF_LIST_OF_FILE);

  return items;
}


#pragma mark -
#pragma mark Public Method
- (NSData *)dataWithContentsOfFile:(NSString *)path
{
  if(!self.unzip) {
    NSLog(@"error: zip file is not opened yet.");
    return nil;
  }

  if(!path.length) {
    NSLog(@"error: specified path is nil.");
    return nil;
  }

  path = [path gnj_stringByNormalizingPathForZip];
  NSData *data = [self.cache objectForKey:path];
  if(data) {
    return data;
  }

  const char *rawFilename = path.UTF8String;
  if(unzLocateFile(self.unzip, rawFilename, 0) != UNZ_OK) {
    NSLog(@"error: cannot locate file specified by path '%@'.", path);
    return nil;
  }

  if(unzOpenCurrentFile(self.unzip) != UNZ_OK) {
    NSLog(@"error: cannot open file specified by path '%@'.", path);
    return nil;
  }

  NSMutableData *mutableData = [NSMutableData data];
  unsigned int bufferSize = 1024;
  void *buffer = (void *)malloc(bufferSize);
  while(1) {
    int length = unzReadCurrentFile(self.unzip, buffer, bufferSize);
    if(length == 0) {
      break;
    }
    else if(length < 0) {
      NSLog(@"error: occurred reading data error: %d", length);
      unzCloseCurrentFile(self.unzip);
      free(buffer);
      return nil;
    }

    [mutableData appendBytes:buffer length:length];
  }

  unzCloseCurrentFile(self.unzip);
  free(buffer);

  [self.cache setObject:mutableData forKey:path];

  return mutableData;
}

@end
