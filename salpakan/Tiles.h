//
//  Tiles.h
//  salpakan
//
//  Created by Marvin Galang on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface Tiles : NSObject 
@property (nonatomic, assign) int row;
@property (nonatomic, assign) int column;
@property (nonatomic, strong) NSString *tilePieceName;
@property (nonatomic, assign) int rank;
@property (nonatomic, strong) NSString *owner;


- (id) initWithRank: (int) rank name:(NSString *) name;

- (void) moveTileLocation:(int)targetRow column:(int) targetColumn;
- (void) removeTileLocation;

@end
