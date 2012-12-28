//
//  DBFDocument.h
//  dBaseFileReader
//
//  Created by Nathan Wood on 28/12/12.
//  Copyright (c) 2012 Nathan Wood. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class DBFDocument, DBFField, DBFResultSet;


@interface DBFDocument : NSObject

- (id)initWithPath:(NSString *)path;

@property (nonatomic, copy) NSString *path;

@property (nonatomic, assign, readonly, getter = isOpen) BOOL open;

@property (nonatomic, readonly) NSArray *fields;

- (BOOL)open:(NSError **)error;
- (BOOL)close;

- (NSInteger)recordCount;
- (DBFResultSet *)fetchResults;

@end


@interface DBFField : NSObject

@property (nonatomic, assign, readonly) int index;
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, assign, readonly) Class type;
@property (nonatomic, assign, readonly) NSInteger width;
@property (nonatomic, assign, readonly) NSInteger decimals;

@end

@interface DBFResultSet : NSObject

@property (nonatomic, assign, readonly) DBFDocument *document;

@property (nonatomic, assign, readonly) int index;
@property (nonatomic, assign, readonly) NSInteger count;

- (BOOL)next;

- (id)valueForFieldAtIndex:(NSUInteger)index;
- (id)valueForFieldWithName:(NSString *)name;

@end