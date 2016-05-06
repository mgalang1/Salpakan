//
//  Board.m
//  salpakan
//
//  Created by Marvin Galang on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "Board.h"
#import "Tiles.h"

@interface Board ()

-(void) initializeTiles;



@end

@implementation Board

@synthesize myTilePieces=_myTilePieces;
@synthesize opponentsTilePieces=_opponentsTilePieces;
@synthesize delegate;

#pragma mark - initializers/destructors
- (id)init {
    self = [super init];
    if (self) {
        
        //initialize
        [self initializeTiles];
        [self randomizeTileLocation];

    }
    return self;
}


//mwthod to initialize owned tiles
-(void) initializeTiles {
    
    self.myTilePieces=[NSMutableArray array];
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"pieces" ofType:@"csv"];
	NSString* fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
	NSArray* pointStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
	
	for(int i = 0; i < pointStrings.count; i++)
        {
		// break the string down even further
		NSString* currentPointString = [pointStrings objectAtIndex:i];
		NSArray* nameRank = [currentPointString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        
        Tiles *tileItem = [[Tiles alloc] initWithRank:[[nameRank objectAtIndex:1]integerValue] name:[nameRank objectAtIndex:0]];
        
        tileItem.owner=@"myTiles";

        //add the tile item to the array
        [self.myTilePieces addObject:tileItem];
        
        }

}

//method to determine if data received from peer is initial setup or a move
-(int) interpretReceivedDataFromPeer:(NSData *) data {
    /*return 1 if initial setup
     return 2 if move]
    */
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSDictionary *myDictionary = [unarchiver decodeObjectForKey:@"salpakanInit"];
    [unarchiver finishDecoding];
    
    if (!myDictionary) return 2;
    else return 1;
    
}

//method to initialize opponents Tiles from the binary data received from the opponent
-(void) initializeOpponentsTile:(NSData *) data {
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSDictionary *myDictionary = [unarchiver decodeObjectForKey:@"salpakanInit"];
    [unarchiver finishDecoding];
    
    
    self.opponentsTilePieces = [myDictionary objectForKey:@"opponentInitialSetup"];
    
    for (int i=0; i<21 ; i++) {
        
        Tiles *tileObj=[self.opponentsTilePieces objectAtIndex:i];
        
        [[self.opponentsTilePieces objectAtIndex:i] setOwner:@"opponentsTile"];
        
        //invert the rows and columns
        [[self.opponentsTilePieces objectAtIndex:i] setRow:ABS(tileObj.row-7)];
        [[self.opponentsTilePieces objectAtIndex:i] setColumn:ABS(tileObj.column-8)];
    }
}


//method to randomize location of owned Tiles
-(void) randomizeTileLocation {
    
    //generate random numbers
    int *points;
    points = malloc(sizeof(int) * 27);
    
    for (int i=0;i<27;i++) {
        points[i]=i;
    }
    
    //randomize own tile Piece
    srand((unsigned)time(NULL));
    for (int i=26;i>=1;i--) {
        int randNumber = (rand() % (i+1));
        
        int swapValue=points[randNumber];
        
        //swap properties of the two objects
        points[randNumber]=points[i];
        points[i]=swapValue;
        
    }

    //assign the random number to own tile pieces
    for (int i=0; i<21; i++) {
        CGFloat x=floorf(points[i]/9);
        CGFloat y=points[i]-(x*9);
        
        [[self.myTilePieces objectAtIndex:i] setRow:x];
        [[self.myTilePieces objectAtIndex:i] setColumn:y];
    }
    
    free(points);
    
}

//Method to Determine if Move is legal
- (int) isMoveAllowed:(int)currentRow currentColumn:(int) currentColumn targetRow:(int)targetRow targetColumn:(int) targetColumn {
    
    //check if move is forward, backward or sideward. Slant move not allowed
    if ((ABS(currentRow-targetRow) + ABS(currentColumn-targetColumn))>1) return 0;
    
    //return move legal
    return 1;
}


-(void) moveTile:(Tiles *)tileToMove targetRow:(int)targetRow targetColumn:(int) targetColumn {
    //move the tilePiece
    [tileToMove moveTileLocation:targetRow column:targetColumn];
}

-(void) moveOpponentTile:(NSData *) data {
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSDictionary *myDictionary = [unarchiver decodeObjectForKey:@"salpakanMove"];
    [unarchiver finishDecoding];
    
    int tileToMoveIndex = [[myDictionary objectForKey:@"tileToMoveIndex"] intValue];
    int targetRow=[[myDictionary objectForKey:@"targetRow"] intValue];
    int targetColumn=[[myDictionary objectForKey:@"targetColumn"] intValue];
    
    if (tileToMoveIndex >=0) {
        [[self.opponentsTilePieces objectAtIndex:tileToMoveIndex] moveTileLocation:targetRow column:targetColumn];
    }
}


-(NSData *) packOwnTileToData {
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
    
    //add array to the dictionary
    [tempDict setObject:self.myTilePieces forKey:@"opponentInitialSetup"];
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:tempDict forKey:@"salpakanInit"];
    [archiver finishEncoding];
    
    return data;
    
}

-(NSData *) packTileMovementToData:(int) tileToMoveIndex targetRow:(int) targetRow targetColumn:(int) targetColumn {
    
    NSMutableDictionary *tempDict=[NSMutableDictionary dictionary];
    
    //add
    [tempDict setObject:[NSNumber numberWithInt:tileToMoveIndex] forKey:@"tileToMoveIndex"];
    [tempDict setObject:[NSNumber numberWithInt:ABS(targetRow-7)] forKey:@"targetRow"];
    [tempDict setObject:[NSNumber numberWithInt:ABS(targetColumn-8)] forKey:@"targetColumn"];
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:tempDict forKey:@"salpakanMove"];
    [archiver finishEncoding];
    
    return data;
}


//temporary methods
-(NSData *) tempMethod1 {
    
    NSMutableArray *tempArray = [NSMutableArray array];
    NSMutableDictionary *tempDict = [NSMutableDictionary dictionary];
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"pieces" ofType:@"csv"];
	NSString* fileContents = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
	NSArray* pointStrings = [fileContents componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
	
	for(int i = 0; i < pointStrings.count; i++)
        {
		// break the string down even further to latitude and longitude fields. 
		NSString* currentPointString = [pointStrings objectAtIndex:i];
		NSArray* nameRank = [currentPointString componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@","]];
        
        Tiles *tileItem = [[Tiles alloc] initWithRank:[[nameRank objectAtIndex:1]integerValue] name:[nameRank objectAtIndex:0]];
        
        //add the tile item to the array
        [tempArray addObject:tileItem];
        
        }
    
    
    //randomize the locations
    //generate random numbers
    int *points;
    points = malloc(sizeof(int) * 27);
    
    for (int i=0;i<27;i++) {
        points[i]=i;
    }
    
    //randomize own tile Piece
    srand((unsigned)time(NULL));
    for (int i=26;i>=1;i--) {
        int randNumber = (rand() % (i+1));
        
        int swapValue=points[randNumber];
        
        //swap properties of the two objects
        points[randNumber]=points[i];
        points[i]=swapValue;
        
    }
    
    //assign the random number to own tile pieces
    for (int i=0; i<21; i++) {
        CGFloat x=floorf(points[i]/9);
        CGFloat y=points[i]-(x*9);
        
        [[tempArray objectAtIndex:i] setRow:x];
        [[tempArray objectAtIndex:i] setColumn:y];
    }
    
    //add array to the dictionary
    [tempDict setObject:tempArray forKey:@"opponentInitialSetup"];
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:tempDict forKey:@"salpakanInit"];
    [archiver finishEncoding];

    return data;
}

//temporary methods
-(NSData *) tempMethod2 {
    //scan tiles in the third row
    
    Tiles * tileToMove;
    int tileToMoveIndex=-1;
    
    for (int i=0; i<21; i++) {
        if ([[self.opponentsTilePieces objectAtIndex:i] row] == 5){        
            tileToMove=[self.opponentsTilePieces objectAtIndex:i];
            tileToMoveIndex=i;
            i=21;
        }
    }
    
    int targetRow=tileToMove.row-1;
    int targetColumn=tileToMove.column;

    NSMutableDictionary *tempDict=[NSMutableDictionary dictionary];
    
    //add
    [tempDict setObject:[NSNumber numberWithInt:tileToMoveIndex] forKey:@"tileToMoveIndex"];
    [tempDict setObject:[NSNumber numberWithInt:targetRow] forKey:@"targetRow"];
    [tempDict setObject:[NSNumber numberWithInt:targetColumn] forKey:@"targetColumn"];
    
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:tempDict forKey:@"salpakanMove"];
    [archiver finishEncoding];
    
    return data;
    
}


-(BOOL)isTileOverlap:(Tiles *) tiles {
    
    //if tile is own tile
    if ([tiles.owner isEqualToString:@"myTiles"]) {
        //scan the current location of opponents Tile pieces
        for (int i=0; i<21; i++) {
            if ([[self.opponentsTilePieces objectAtIndex:i] row] == tiles.row && [[self.opponentsTilePieces objectAtIndex:i] column]==tiles.column) {
                    return YES;
                }
            }
    }
    
    //if tile is opponent tile
    if ([tiles.owner isEqualToString:@"opponentsTile"]) {
        //scan the current location of opponents Tile pieces
        for (int i=0; i<21; i++) {
            if ([[self.myTilePieces objectAtIndex:i] row] == tiles.row && [[self.myTilePieces objectAtIndex:i] column]==tiles.column) {
                return YES;
            }
        }
    }
    

    return NO;
    
}


-(int) checkTileWin:(int) ownTileIndex opponentTileIndex:(int) opponentTileIndex aggressor:(int) agressor {
    /*
     agressor 0 - own Tile
     agressor 1 - opponents Tile
     
     return 1 id own Tile Win
     return 2 if opponent Tile Win
     return 3 if ownTileWin and ended the game
     return 4 if opponentTile win and ended the game
     return 5 even
     */
    
    int ownRank=[[self.myTilePieces objectAtIndex:ownTileIndex] rank];
    int opponentRank=[[self.opponentsTilePieces objectAtIndex:opponentTileIndex] rank];
    
    //if none of the tile piece is a flag
    if (ownRank>0 && opponentRank>0) {
        //if spy and private collide
        if (ownRank==14 && opponentRank==1) return 2;
        else if (ownRank==1 && opponentRank==14) return 1;
        else if (ownRank>opponentRank) return 1;
        else if (ownRank<opponentRank) return 2;
        else return 5;
    }
    else if (ownRank==0 && opponentRank==0 && agressor==0) return 3;
    else if (ownRank==0 && opponentRank==0 && agressor==1) return 4;
    else if (ownRank==0 && opponentRank>0) return 4;
    else if (ownRank>0 && opponentRank==0) return 3;
    else return 1;

}

@end
