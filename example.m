//
//  main.m
//  dBaseFileReader
//
//  Created by Nathan Wood on 28/12/12.
//  Copyright (c) 2012 Nathan Wood. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DBFDocument.h"

int main(int argc, const char * argv[])
{

    @autoreleasepool {
        NSString *path = @"database.dbf";
        DBFDocument *doc = [[DBFDocument alloc] initWithPath:path];
        [doc open:nil];
        
        for (DBFField *field in doc.fields)
        {
            printf("%s\t|\t", [field.name UTF8String]);
        }
        
        printf("\n");
        
        DBFResultSet *set = [doc fetchResults];
        while ([set next])
        {
            for (int i = 0; i < doc.fields.count; i++) {
                id value = [set valueForFieldAtIndex:i];
                if (value)
                    printf("%s\t|\t", [[value description] UTF8String]);
                else
                    printf("\t\t|\t");
            }
        }
    }
    return 0;
}

