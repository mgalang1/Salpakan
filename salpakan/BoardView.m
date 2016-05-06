//
//  BoardView.m
//  salpakan
//
//  Created by Marvin Galang on 4/5/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BoardView.h"

@interface BoardView()

@property (nonatomic, assign) CGSize tileSize;

@end


@implementation BoardView

@synthesize tileSize=_tileSize;

- (id)initWithFrame:(CGRect)frame tileSize:(CGSize) tileSize
{
    self = [super initWithFrame:frame];
    if (self) {
        self.tileSize=tileSize;
        // Initialization code
    }
    return self;
}


// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
    
    [[UIColor blackColor] setFill];
    UIRectFill(rect);
    
    //draw the board
    for (int i=0; i<72; i++) {
        CGFloat x=floorf(i/9);
        CGFloat y=i-(x*9);
        
        if (i%2==0)  [[UIColor lightGrayColor] set];
        else  [[UIColor brownColor] set];
        
        UIRectFill(CGRectMake(y*self.tileSize.height, x*self.tileSize.height, self.tileSize.height, self.tileSize.height));
        
    }
    
    
}

@end
