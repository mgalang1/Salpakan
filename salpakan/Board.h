//
//  Board.h
//  salpakan
//
//  Created by Marvin Galang on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Tiles.h"

@class Board;
@protocol BoardDelegate <NSObject>
@optional
- (void) tileMoveToOpponentPiece:(Tiles*)ownTile opponentsTile:(Tiles *)opponentTile;
@end


@interface Board : NSObject


@property (nonatomic, strong) NSMutableArray *myTilePieces;
@property (nonatomic, strong) NSMutableArray *opponentsTilePieces;
@property (strong, nonatomic) id <BoardDelegate> delegate;

-(int) isMoveAllowed:(int)currentRow currentColumn:(int) currentColumn targetRow:(int)targetRow targetColumn:(int) targetColumn;
-(void) randomizeTileLocation;
-(void) moveTile:(Tiles *)tileToMove targetRow:(int)targetRow targetColumn:(int) targetColumn;
-(void) moveOpponentTile:(NSData *) data;
-(void) initializeOpponentsTile:(NSData *) data;
-(BOOL) isTileOverlap:(Tiles *) tiles;
-(int) checkTileWin:(int) ownTileIndex opponentTileIndex:(int) opponentTileIndex aggressor:(int) agressor;
-(NSData *) packOwnTileToData;
-(NSData *) packTileMovementToData:(int) tileToMoveIndex targetRow:(int) targetRow targetColumn:(int) targetColumn;
-(int) interpretReceivedDataFromPeer:(NSData *) data;

//temp methods
-(NSData *) tempMethod1;
-(NSData *) tempMethod2;


@end
