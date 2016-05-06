//
//  Tiles.m
//  salpakan
//
//  Created by Marvin Galang on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Tiles.h"

@implementation Tiles


@synthesize row=_row;
@synthesize column=_column;
@synthesize tilePieceName=_tilePieceName;
@synthesize rank=_rank;
@synthesize owner=_owner;


- (id) initWithRank: (int) rank name:(NSString *) name {
    
    self = [super init];
    if (self) {
        self.tilePieceName=name;
        self.rank=rank;
        self.row=-100;
        self.column=-100;
    }
    
    return self;
}


- (void) moveTileLocation:(int)targetRow column:(int) targetColumn {
    
    if (ABS(self.row-targetRow)>0) {
        self.row=targetRow;
    }
    
    if(ABS(self.column-targetColumn)>0) {
        self.column=targetColumn;
    }
}

- (void) removeTileLocation {
    self.row=-100;
    self.column=-100;
}


#pragma mark - Archieving

- (id)initWithCoder:(NSCoder *)decoder;
{
    if ((self = [super init])) {
        self.tilePieceName = [decoder decodeObjectForKey:@"tilePieceName"];
        self.owner = [decoder decodeObjectForKey:@"owner"];
        [decoder decodeValueOfObjCType:@encode(int) at:&_row];
        [decoder decodeValueOfObjCType:@encode(int) at:&_column];
        [decoder decodeValueOfObjCType:@encode(int) at:&_rank];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder;
{
    [coder encodeObject:self.tilePieceName forKey:@"tilePieceName"];
    [coder encodeObject:self.owner forKey:@"owner"];
    [coder encodeValueOfObjCType:@encode(int) at:&_row];
    [coder encodeValueOfObjCType:@encode(int) at:&_column];
    [coder encodeValueOfObjCType:@encode(int) at:&_rank];
}



@end
