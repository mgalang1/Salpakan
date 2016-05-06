//
//  BoardViewController.m
//  salpakan
//
//  Created by Marvin Galang on 4/2/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "BoardViewController.h"
#import "Tiles.h"
#import "Board.h"
#import "BoardView.h"
#import "TileView.h"
#import <GameKit/GameKit.h>

@interface BoardViewController()  <UIGestureRecognizerDelegate, BoardDelegate, GKPeerPickerControllerDelegate, GKSessionDelegate>

@property (nonatomic, strong) GKSession *gameSession;
@property (nonatomic, strong) GKPeerPickerController *peerPickerController;

@property (nonatomic, weak) IBOutlet UIView *faceOffView;
@property (nonatomic, strong) IBOutlet TileView *faceOffOpponentImageView;
@property (nonatomic, strong) IBOutlet TileView *faceOffOwnImageView;
@property (nonatomic, weak) IBOutlet UIButton *randomButton;
@property (nonatomic, weak) IBOutlet UIButton *finishSetupButton;
@property (nonatomic, weak) IBOutlet UIButton *connectButton;
@property (nonatomic, weak) IBOutlet UILabel *statusLabel;
@property (nonatomic, weak) IBOutlet UILabel *turnLabel;

@property (nonatomic, assign, getter=isMyTurn) BOOL myTurn;
@property (nonatomic, assign, getter=isGameStarted) BOOL gameStarted;
@property (nonatomic, strong) Board *tileBoard;
@property (nonatomic, strong) TileView *currentImageView;

@property (nonatomic, assign, getter=isTileSelected) BOOL tileSelected;
@property (nonatomic, assign) CGSize tileSize;
@property (nonatomic, assign) CGFloat xOffset;
//@property (nonatomic, strong) Tiles *ownTile;
//@property (nonatomic, strong) Tiles *opponentTile;


-(void)addGestureRecognizersToPiece:(TileView *)tilePiece;
-(void)addGestureRecognizersToBoard:(BoardView *)board;
-(void) calcTileSize:(CGRect) boundRect;
-(void)selectTilePiece:(UITapGestureRecognizer *)gestureRecognizer;
-(void)moveTilePiece:(UITapGestureRecognizer *)gestureRecognizer;
-(void) addOwnTile;
-(void) addOpponentTile;
-(TileView *) tileViewInRow:(int) row withColumn:(int) column;
-(void) checkOverlap:(Tiles *) tileObj;
-(void) eliminateTileView:(TileView *) ownTileView opponentTileView:(TileView *) opponentTileView;
-(void)sendDataToPeer:(NSData *)data;

-(IBAction)handleConnectTapped:(id)sender;
-(IBAction)doneSetup:(id)sender;
-(IBAction)shuffleTiles:(id)sender;


//temp IBAction Methods
-(IBAction) receivedOpponentSetup:(id)sender;
-(IBAction) receivedNewMoveByOpponent:(id)sender;

@end

@implementation BoardViewController

@synthesize gameSession=_gameSession;
@synthesize peerPickerController = _peerPickerController;

@synthesize faceOffView=_faceOffView;
@synthesize faceOffOpponentImageView=_faceOffOpponentImageView;
@synthesize faceOffOwnImageView=_faceOffOwnImageView;
@synthesize randomButton=_randomButton;
@synthesize finishSetupButton=_finishSetupButton;
@synthesize connectButton=_connectButton;
@synthesize statusLabel=_statusLabel;
@synthesize turnLabel=_turnLabel;

@synthesize myTurn=_myTurn;
@synthesize gameStarted=_gameStarted;
@synthesize tileBoard=_tileBoard;
@synthesize currentImageView=_currentImageView;
@synthesize tileSelected=_tileSelected;
@synthesize tileSize=_tileSize;
@synthesize xOffset=_xOffset;
//@synthesize ownTile=_ownTile;
//@synthesize opponentTile=_opponentTile;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        //create the board object
        self.tileBoard=[[Board alloc] init];
        self.tileBoard.delegate=self;
        self.tileSelected=NO;
        
        self.gameStarted=NO;
        //temporary only will change later
        self.myTurn=YES;
        
        
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.turnLabel.text=nil;
    self.statusLabel.text=nil;
    
    self.finishSetupButton.enabled=NO;
    self.randomButton.enabled=NO;
    
    [self calcTileSize:[[UIScreen mainScreen] applicationFrame]];
    
    BoardView *board=[[BoardView alloc] initWithFrame:CGRectMake(self.xOffset, 0, 9*self.tileSize.width, 8*self.tileSize.height) tileSize:self.tileSize];
    
    board.userInteractionEnabled=YES;
    [self addGestureRecognizersToBoard:board];
    
    [self.view addSubview:board];
    
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

-(void) calcTileSize:(CGRect) boundRect {
    self.tileSize=CGSizeMake(floorf(boundRect.size.width/9), floorf(boundRect.size.width/9));
    self.xOffset=floorf((boundRect.size.width-(9*self.tileSize.width))/2);
}

#pragma mark - Gesture Recognizers Methods

//add gesture recognizer to owned tile pieces
-(void)addGestureRecognizersToPiece:(TileView *)tilePiece {
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectTilePiece:)];
    [tilePiece addGestureRecognizer:tapGesture];
}

//add gesture recognizer to the board
-(void)addGestureRecognizersToBoard:(BoardView *)board {
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moveTilePiece:)];
    [board addGestureRecognizer:tapGesture];
}

//gesture recognizers selector
- (void)selectTilePiece:(UITapGestureRecognizer *)gestureRecognizer
{
    
    if (self.isMyTurn==NO) return;
        
    //revert back the borderline of the previous imageView to normal Width
    self.currentImageView.layer.borderColor=[UIColor greenColor].CGColor;
    self.currentImageView.layer.borderWidth=0.8;
    
    //highlight the selected Tile
    self.currentImageView= (TileView *) [gestureRecognizer view];
    self.currentImageView.layer.borderColor=[UIColor yellowColor].CGColor;
    self.currentImageView.layer.borderWidth=4;
    
    self.tileSelected=YES;
}

- (void)moveTilePiece:(UITapGestureRecognizer *)gestureRecognizer
{
    
    if (self.isTileSelected==NO) return;
    
    //derive row and column of the current image view
    
    Tiles *tileToMove=[self.tileBoard.myTilePieces objectAtIndex:self.currentImageView.tileIndex];
    
    int currentRow=tileToMove.row;
    int currentColumn=tileToMove.column;
    
    //CGPoint imageViewCenter=self.currentImageView.center;
    //imageViewCenter.x=imageViewCenter.x-self.xOffset;
    
    //int currentRow=ABS(floorf(imageViewCenter.y/self.tileSize.height)-7);
    //int currentColumn=floorf(imageViewCenter.x/self.tileSize.width);
    
    
    
    //derive row and column of the tap location in board
    CGPoint tapLocation = [gestureRecognizer locationInView:[gestureRecognizer view]];
    tapLocation.x=tapLocation.x-self.xOffset;
    
    int targetRow=ABS(floorf(tapLocation.y/self.tileSize.height)-7);
    int targetColumn=floorf(tapLocation.x/self.tileSize.width);
    
    
    //determine if move is allowed
    int moveAllowed=[self.tileBoard isMoveAllowed:currentRow currentColumn:currentColumn targetRow:targetRow targetColumn:targetColumn];
    
    if (moveAllowed==0) {
        //revert back the borderline of the previous imageView to normal Width
        self.currentImageView.layer.borderColor=[UIColor greenColor].CGColor;
        self.currentImageView.layer.borderWidth=0.8;
    }
    
    if (moveAllowed==1) {
        
        //move the tilePiece
        [self.tileBoard moveTile:tileToMove targetRow:targetRow targetColumn:targetColumn];
        
        [self sendDataToPeer:[self.tileBoard packTileMovementToData:self.currentImageView.tileIndex targetRow:targetRow targetColumn:targetColumn]];
        self.myTurn=NO;
        self.turnLabel.text=@"Waiting for Opponent";
        
    }
    
    
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)obj
						change:(NSDictionary *)change
					   context:(void *)context
{
    
	NSLog(@"change in %@ occured",keyPath);
    
    Tiles *tileObj=(Tiles *) obj;
    TileView *imageViewToMove;
    
    
    if ([keyPath isEqualToString:@"row"] && tileObj.row>=0) {
        
        imageViewToMove=[self tileViewInRow:[[change valueForKey:@"old"] intValue] withColumn:tileObj.column];
        
        int changeInRow=tileObj.row - [[change valueForKey:@"old"] intValue];
        
        CGPoint targetCenter=CGPointMake(imageViewToMove.center.x,(changeInRow*self.tileSize.height*-1)+imageViewToMove.center.y);
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationCurveLinear animations:^{
            imageViewToMove.center=targetCenter;
            
        } completion:^(BOOL finished){ 
            //revert back the borderline of the previous imageView to normal Width
            
            if ([imageViewToMove.owner isEqualToString:@"myTiles"])
                imageViewToMove.layer.borderColor=[UIColor greenColor].CGColor;
            else imageViewToMove.layer.borderColor=[UIColor redColor].CGColor;
            
            imageViewToMove.layer.borderWidth=0.8;
            
            //update the row
            imageViewToMove.row=tileObj.row;
            
            self.tileSelected=NO;
            
            //if (self.gameStarted==YES) {
                [self checkOverlap:tileObj];
            //}
            
            
        }];
        
    }
    
    if ([keyPath isEqualToString:@"column"] && tileObj.column>=0) {
        imageViewToMove=[self tileViewInRow:tileObj.row withColumn:[[change valueForKey:@"old"] intValue]];
        
        int changeInCol=tileObj.column - [[change valueForKey:@"old"] intValue];
        
        CGPoint targetCenter=CGPointMake((changeInCol*self.tileSize.height)+imageViewToMove.center.x, imageViewToMove.center.y);
        
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationCurveLinear animations:^{
            imageViewToMove.center=targetCenter;
            
        } completion:^(BOOL finished){ 
            //revert back the borderline of the previous imageView to normal Width
            if ([imageViewToMove.owner isEqualToString:@"myTiles"])
                imageViewToMove.layer.borderColor=[UIColor greenColor].CGColor;
            else imageViewToMove.layer.borderColor=[UIColor redColor].CGColor;
            
            imageViewToMove.layer.borderWidth=0.8;
            
            //update the column
            imageViewToMove.column=tileObj.column;
            
            self.tileSelected=NO;
            
            //if (self.gameStarted==YES) {
                [self checkOverlap:tileObj];
            //}
            
        }];
        
    }
    
    
}


-(void) checkOverlap:(Tiles *) tileObj {
    
    //test if the newly move object overlap to opponents tile
    BOOL isOverlap=[self.tileBoard isTileOverlap:tileObj];
    
    if (isOverlap==YES) {
        //determine the tileViews that overlapped
        
        TileView *ownTileView, *opponentTileView;
        for (UIView *oneView in self.view.subviews) {
            if ([oneView isMemberOfClass:[TileView class]]) {
                if([(TileView *)oneView row]==tileObj.row && [(TileView *)oneView column]==tileObj.column) {
                    if ([[(TileView *) oneView owner] isEqualToString:@"myTiles"])
                        ownTileView=(TileView *) oneView;
                    else opponentTileView=(TileView *) oneView;
                }
            }
        }
        
        
        [self eliminateTileView:ownTileView opponentTileView:opponentTileView];
    }

    
}

-(void) eliminateTileView:(TileView *) ownTileView opponentTileView:(TileView *) opponentTileView {
    
        
    //show face off NIB
    UINib *faceOffNib = [UINib nibWithNibName:@"faceoff_phone" bundle:nil];
    [faceOffNib instantiateWithOwner:self options:nil];
        
    [self.view addSubview:self.faceOffView];
        
    //set frame of the popup View
    self.faceOffView.center = CGPointMake(self.xOffset+(self.tileSize.width*4.5), self.tileSize.height*4);
    self.faceOffView.alpha=0;
        
    //set the image inside the faceoff view
    self.faceOffOwnImageView.image=[UIImage imageNamed:[NSString stringWithFormat:@"%@.gif",[[self.tileBoard.myTilePieces objectAtIndex:ownTileView.tileIndex] tilePieceName]]];
    self.faceOffOwnImageView.layer.borderColor=[UIColor greenColor].CGColor;
    self.faceOffOwnImageView.layer.borderWidth=0.8;

    self.faceOffOpponentImageView.image=[UIImage imageNamed:@"CyanSquare.png"];
    
    // self.faceOffOpponentImageView.image=[UIImage imageNamed:[NSString stringWithFormat:@"%@.gif",[[self.tileBoard.opponentsTilePieces objectAtIndex:opponentTileView.tileIndex] tilePieceName]]];
    self.faceOffOpponentImageView.layer.borderColor=[UIColor greenColor].CGColor;
    self.faceOffOpponentImageView.layer.borderWidth=0.8;

    [UIView animateWithDuration:1.0 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
            _faceOffView.alpha = 1.0; 
        } completion:nil];
    
    
    int tileWinner=[self.tileBoard checkTileWin:ownTileView.tileIndex opponentTileIndex:opponentTileView.tileIndex aggressor:1];
    
    /*
     agressor 0 - own Tile
     agressor 1 - opponents Tile
     
     return 1 id own Tile Win
     return 2 if opponent Tile Win
     return 3 if ownTileWin and ended the game
     return 4 if opponentTile win and ended the game
     return 5 even
     */
    
    if (tileWinner==1 || tileWinner==3) {
        [UIView animateWithDuration:4.0 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
            _faceOffOpponentImageView.alpha = 0.0; 
        } completion:^(BOOL finished){
            [_faceOffView removeFromSuperview];
            
            //move the tilePiece
            [self.tileBoard moveTile:[self.tileBoard.opponentsTilePieces objectAtIndex:opponentTileView.tileIndex] targetRow:-100 targetColumn:-100];
            
            [opponentTileView removeFromSuperview];
            
            if (tileWinner==3) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Congratulations" message:@"You Won the game" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
                [alert show];
            }
        
        }];
    }
    
    if (tileWinner==2 || tileWinner==4) {
        [UIView animateWithDuration:4.0 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
            _faceOffOwnImageView.alpha = 0.0; 
        } completion:^(BOOL finished){
            [_faceOffView removeFromSuperview];
            
            //move the tilePiece
            [self.tileBoard moveTile:[self.tileBoard.myTilePieces objectAtIndex:ownTileView.tileIndex] targetRow:-100 targetColumn:-100];
            
            [ownTileView removeFromSuperview];
            
            if (tileWinner==4) {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"You Lose" message:@"Better Luck Next Time" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil,nil];
                [alert show];
            }
            
        }];
    }
    
    if (tileWinner==5) {
        [UIView animateWithDuration:4.0 delay:0.0 options:UIViewAnimationCurveEaseInOut animations:^{
            _faceOffOwnImageView.alpha = 0.0; 
            _faceOffOpponentImageView.alpha = 0.0;
        } completion:^(BOOL finished){
            [_faceOffView removeFromSuperview];
            
            //move the tilePiece
            [self.tileBoard moveTile:[self.tileBoard.myTilePieces objectAtIndex:ownTileView.tileIndex] targetRow:-100 targetColumn:-100];
            
            [self.tileBoard moveTile:[self.tileBoard.opponentsTilePieces objectAtIndex:opponentTileView.tileIndex] targetRow:-100 targetColumn:-100];
            
            [ownTileView removeFromSuperview];
            [opponentTileView removeFromSuperview];
            
        }];
    }
    
    
    
}


-(TileView *) tileViewInRow:(int) row withColumn:(int) column {
    
    //determine the correct image View that corresponds to the Tile Object
    TileView *imageViewToMove;
    for (UIView *oneView in self.view.subviews) {
        if ([oneView isMemberOfClass:[TileView class]]) {
            if([(TileView *)oneView row]==row && [(TileView *)oneView column]==column) imageViewToMove=(TileView *) oneView;
            
        }
    }
    
    return imageViewToMove;
}


- (IBAction)handleConnectTapped:(id)sender;
{
    self.peerPickerController = [[GKPeerPickerController alloc] init];
    self.peerPickerController.delegate = self;
    self.peerPickerController.connectionTypesMask = GKPeerPickerConnectionTypeNearby;
    
    // | GKPeerPickerConnectionTypeOnline;
    
    [self.peerPickerController show];
}

-(IBAction)doneSetup:(id)sender {
    [self sendDataToPeer:[self.tileBoard packOwnTileToData]];
    self.randomButton.enabled=NO;
    self.finishSetupButton.enabled=NO;
}

-(IBAction)shuffleTiles:(id)sender {
    
    [self.tileBoard randomizeTileLocation];
}

-(void) addOwnTile {
    
    //add own tile Pieces
    for (int i=0; i<21; i++) {
        Tiles *overlayTile=[self.tileBoard.myTilePieces objectAtIndex:i];
        
        //start observing the Tile Objects
        [overlayTile addObserver:self
                      forKeyPath:@"row"
                         options:NSKeyValueObservingOptionOld
                         context:NULL];
        
        [overlayTile addObserver:self
                      forKeyPath:@"column"
                         options:NSKeyValueObservingOptionOld
                         context:NULL];
        
        
        TileView *imageView=[[TileView alloc] init];
        imageView.image=[UIImage imageNamed:[NSString stringWithFormat:@"%@.gif",overlayTile.tilePieceName]];
        imageView.frame=CGRectMake(self.xOffset+(overlayTile.column*self.tileSize.width), ABS(overlayTile.row-7)* self.tileSize.width, self.tileSize.width, self.tileSize.height);
        
        imageView.tileIndex=i;
        imageView.row=overlayTile.row;
        imageView.column=overlayTile.column;
        imageView.owner=overlayTile.owner;
        
        imageView.userInteractionEnabled=YES;
        [self addGestureRecognizersToPiece:imageView];
        imageView.layer.borderColor=[UIColor greenColor].CGColor;
        imageView.layer.borderWidth=0.8;
        [self.view addSubview:imageView];
    }
    
    self.randomButton.enabled=YES;
    self.finishSetupButton.enabled=YES;
    self.statusLabel.text=@"Waiting for opponent";
    
}

-(void) addOpponentTile {
    
    //add opponent tile Pieces
    for (int i=0; i<21; i++) {
        Tiles *overlayTile=[self.tileBoard.opponentsTilePieces objectAtIndex:i];
        
        //NSLog(@"%@",overlayTile);
        
        //start observing the Opponent Tile Objects
        [overlayTile addObserver:self
                      forKeyPath:@"row"
                         options:NSKeyValueObservingOptionOld
                         context:NULL];
        
        [overlayTile addObserver:self
                      forKeyPath:@"column"
                         options:NSKeyValueObservingOptionOld
                         context:NULL];
        
        TileView *imageView=[[TileView alloc] init];
        imageView.image=[UIImage imageNamed:@"CyanSquare.png"];
        imageView.frame=CGRectMake(self.xOffset+(overlayTile.column*self.tileSize.width), ABS(overlayTile.row-7)* self.tileSize.width, self.tileSize.width, self.tileSize.height);
                
        //imageView.frame=CGRectMake(self.xOffset+(ABS(overlayTile.column-8) * self.tileSize.width), overlayTile.row* self.tileSize.width, self.tileSize.width, self.tileSize.height);
        //imageView.transform = CGAffineTransformMakeRotation(M_PI);
        
        imageView.tileIndex=i;
        imageView.row=overlayTile.row;
        imageView.column=overlayTile.column;
        imageView.owner=overlayTile.owner;

        imageView.layer.borderColor=[UIColor redColor].CGColor;
        imageView.layer.borderWidth=0.8;
        [self.view addSubview:imageView];
    }
    
    self.statusLabel.text=@"Game Started";
    
}

#pragma mark - GKPeerPickerControllerDelegate

- (void)peerPickerController:(GKPeerPickerController *)picker didSelectConnectionType:(GKPeerPickerConnectionType)type;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (GKSession *)peerPickerController:(GKPeerPickerController *)picker sessionForConnectionType:(GKPeerPickerConnectionType)type;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    return [[GKSession alloc] initWithSessionID:@"Salpakan" displayName:nil sessionMode:GKSessionModePeer];
}

- (void)peerPickerController:(GKPeerPickerController *)picker didConnectPeer:(NSString *)peerID toSession:(GKSession *)session;
{
    NSLog(@"%s: %@: %@", __PRETTY_FUNCTION__, peerID, [session displayNameForPeer:peerID]);
    
    self.gameSession = session;
    self.gameSession.delegate = self;
    [self.gameSession setDataReceiveHandler:self withContext:nil];
    
    self.connectButton.enabled=NO;
    
    [self addOwnTile];
    
    self.peerPickerController.delegate=nil;
    [self.peerPickerController dismiss];
}

- (void)peerPickerControllerDidCancel:(GKPeerPickerController *)picker;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    self.peerPickerController.delegate=nil;
    
    //temporary setup simulating after connection is established
    //[self addOwnTile];
    
    
}


#pragma mark - GKSessionDelegate

- (void)session:(GKSession *)session peer:(NSString *)peerID didChangeState:(GKPeerConnectionState)state;
{
    NSLog(@"%s: %@: %d", __PRETTY_FUNCTION__, peerID, state);
}

/* Indicates a connection request was received from another peer. 
 Accept by calling -acceptConnectionFromPeer:
 Deny by calling -denyConnectionFromPeer:
 */
- (void)session:(GKSession *)session didReceiveConnectionRequestFromPeer:(NSString *)peerID;
{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, peerID);
}

/* Indicates a connection error occurred with a peer, which includes connection request failures, or disconnects due to timeouts.
 */
- (void)session:(GKSession *)session connectionWithPeerFailed:(NSString *)peerID withError:(NSError *)error;
{
    NSLog(@"%s: %@: %@", __PRETTY_FUNCTION__, peerID, error);
    
}

/* Indicates an error occurred with the session such as failing to make available.
 */
- (void)session:(GKSession *)session didFailWithError:(NSError *)error;
{
    NSLog(@"%s: %@", __PRETTY_FUNCTION__, error);
}

#pragma mark - Receiving data

- (void)receiveData:(NSData *)data fromPeer:(NSString *)peerID inSession:(GKSession *)session context:(void *)context;
{
    NSLog(@"%s", __PRETTY_FUNCTION__);
    
    /*return 1 if initial setup
     return 2 if move]
     */
    
    int dataContent=[self.tileBoard interpretReceivedDataFromPeer:data];
    
    if (dataContent==1) {
        [self.tileBoard initializeOpponentsTile:data];
        [self addOpponentTile];
    }
    
    if (dataContent==2) {
        [self.tileBoard moveOpponentTile:data];
        self.myTurn=YES;
        self.turnLabel.text=@"Your Turn";
    }
    
    //self.transcriptTextView.text = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}

#pragma mark - Sending data

- (void)sendDataToPeer:(NSData *)data;
{
    BOOL didSend = [self.gameSession sendDataToAllPeers:data withDataMode:GKSendDataReliable error:nil];
    NSLog(@"%s: %d", __PRETTY_FUNCTION__, didSend);
}

#pragma mark - temp methods
-(IBAction) receivedOpponentSetup:(id)sender {
    
    NSData *data = [self.tileBoard tempMethod1];
    [self.tileBoard initializeOpponentsTile:data];
    [self addOpponentTile];
}

-(IBAction) receivedNewMoveByOpponent:(id)sender {
    
    NSData *data = [self.tileBoard tempMethod2];
    [self.tileBoard moveOpponentTile:data];
    
}



@end
