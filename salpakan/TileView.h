//
//  TileView.h
//  salpakan
//
//  Created by Marvin Galang on 4/7/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TileView : UIImageView
@property (nonatomic, assign) int tileIndex;
@property (nonatomic, assign) int row;
@property (nonatomic, assign) int column;
@property (nonatomic, strong) NSString *owner;

@end
