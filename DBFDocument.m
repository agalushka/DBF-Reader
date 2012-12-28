//
//  DBFDocument.m
//  dBaseFileReader
//
//  Created by Nathan Wood on 28/12/12.
//  Copyright (c) 2012 Nathan Wood. All rights reserved.
//

#import "DBFDocument.h"
#import "shapefil.h"


@interface DBFDocument () {
@package
    DBFHandle _dbf_handle;
}

@property (nonatomic, assign, readwrite, getter = isOpen) BOOL open;

@property (nonatomic, readonly) NSMutableArray *internalFields;

- (void)readFields;

@end


@interface DBFField ()

+ (Class)classForDBFFieldType:(DBFFieldType)type;

- (id)initWithIndex:(NSInteger)index name:(NSString *)name type:(DBFFieldType)type width:(NSInteger)width decimals:(NSInteger)decimals;

@property (nonatomic, assign, readwrite) int index;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, assign, readwrite) Class type;
@property (nonatomic, assign, readwrite) NSInteger width;
@property (nonatomic, assign, readwrite) NSInteger decimals;

@property (nonatomic, assign) DBFFieldType DBFType;


@end


@interface DBFResultSet ()

- (id)initWithDocument:(DBFDocument *)document;

@property (nonatomic, assign, readwrite) DBFDocument *document;

@property (nonatomic, assign, readwrite) int index;
@property (nonatomic, assign, readwrite) NSInteger count;

@end


@implementation DBFDocument

@synthesize path = _path, open = _open;
@synthesize internalFields = _internalFields;

- (id)initWithPath:(NSString *)path
{
    self = [super init];
    if (self)
    {
        self.path = path;
    }
    return self;
}

- (void)setPath:(NSString *)path
{
    if (self->_path != path && self.open == NO)
    {
        self->_path = [path copy];
    }
}

- (BOOL)open:(NSError **)error
{
    if (self.isOpen)
    {
        if (error != nil)
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:EPERM
                                     userInfo:[NSDictionary dictionaryWithObject:@"File already open" forKey:NSLocalizedDescriptionKey]];
        return NO;
    }
    
    if ((self->_dbf_handle = DBFOpen([self.path UTF8String], "rb")) == NULL)
    {
        if (error != nil)
            *error = [NSError errorWithDomain:NSOSStatusErrorDomain
                                         code:EIO
                                     userInfo:[NSDictionary dictionaryWithObject:@"Could not open file" forKey:NSLocalizedDescriptionKey]];
        return NO;
    }
    
    self.open = YES;
    
    [self readFields];
    
    return YES;
}

- (BOOL)close
{
    DBFClose(self->_dbf_handle);
    self->_dbf_handle = NULL;
    self.open = NO;
    return YES;
}

- (NSArray *)fields
{
    return self.internalFields;
}

- (NSMutableArray *)internalFields
{
    if (self->_internalFields == nil)
        self->_internalFields = [[NSMutableArray alloc] init];
    
    return self->_internalFields;
}

- (void)readFields
{
    if (self.isOpen == NO)
        return;
    
    NSMutableArray *fields = self.internalFields;
    DBFField *field = nil;
    DBFFieldType fieldType;
    char fieldName[12];
    NSString *nameString = nil;
    int width = 0;
    int decimals = 0;
    for (int i = 0; i < DBFGetFieldCount(self->_dbf_handle); i++)
    {
        fieldType = DBFGetFieldInfo(self->_dbf_handle, i, fieldName, &width, &decimals);
        nameString = [[NSString alloc] initWithUTF8String:fieldName];
        field = [[DBFField alloc] initWithIndex:i
                                           name:nameString
                                           type:fieldType
                                          width:width
                                       decimals:decimals];
        if (field != nil)
            [fields addObject:field];
    }
}

- (NSInteger)recordCount
{
    if (self.isOpen)
        return DBFGetRecordCount(self->_dbf_handle);
    return -1;
}

- (DBFResultSet *)fetchResults
{
    return [[DBFResultSet alloc] initWithDocument:self];
}

@end


@implementation DBFField

@synthesize index = _index, name = _name, type = _type;
@synthesize width = _width, decimals = _decimals, DBFType = _DBFType;

- (id)initWithIndex:(NSInteger)index name:(NSString *)name
               type:(DBFFieldType)type width:(NSInteger)width decimals:(NSInteger)decimals
{
    self = [super init];
    if (self)
    {
        Class typeClass = [[self class] classForDBFFieldType:type];
        if (typeClass == Nil)
        {
            self = nil;
            return nil;
        }
        
        self.index = index;
        self.name = name;
        self.type = typeClass;
        self.width = width;
        self.decimals = decimals;
        
        self.DBFType = type;
    }
    return self;
}

+ (Class)classForDBFFieldType:(DBFFieldType)type
{
    switch (type) {
        case FTInteger:
        case FTDouble:
        case FTLogical:
            return [NSNumber class];
        case FTString:
            return [NSString class];
        case FTDate:
            return [NSDate class];
        case FTInvalid:
        default:
            break;
    }
    return Nil;
}

@end


@implementation DBFResultSet

@synthesize document = _document, index = _index, count = _count;

- (id)initWithDocument:(DBFDocument *)document
{
    self = [super init];
    if (self)
    {
        self.document = document;
        self.index = -1;
        
        self.count = (self.document.isOpen) ? self.document.recordCount : -1;
    }
    return self;
}

- (BOOL)next
{
    return (self.document.isOpen && ++self.index < self.count);
}

- (id)valueForField:(DBFField *)field
{
    if (DBFIsAttributeNULL(self.document->_dbf_handle, self.index, field.index))
        return nil;
    
    switch (field.DBFType) {
        case FTString:
            return [NSString stringWithUTF8String:DBFReadStringAttribute(self.document->_dbf_handle, self.index, field.index)];
            break;
        case FTInteger:
            return [NSNumber numberWithInt:
                    DBFReadIntegerAttribute(self.document->_dbf_handle, self.index, field.index)];
        case FTDouble:
            return [NSNumber numberWithDouble:
                    DBFReadDoubleAttribute(self.document->_dbf_handle, self.index, field.index)];
        case FTLogical:
            return [NSNumber numberWithChar:
                    *DBFReadLogicalAttribute(self.document->_dbf_handle, self.index, field.index)];
        default:
            break;
    }
    
    return nil;
}

- (id)valueForFieldAtIndex:(NSUInteger)index
{
    if (self.document.isOpen == NO)
        return nil;
    
    DBFField *field = [self.document.fields objectAtIndex:index];
    return [self valueForField:field];
}

- (id)valueForFieldWithName:(NSString *)name
{
    if (self.document.isOpen == NO)
        return nil;
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"name == %@", name];
    DBFField *field = [[self.document.fields filteredArrayUsingPredicate:pred] lastObject];
    return [self valueForField:field];
}

@end