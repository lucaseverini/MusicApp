//
//  FileTableController.h
//  MusicApp
//
//  Created by Luca Severini on 7/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//


@interface FileTableController : UITableViewController
{
    NSString *fileNames[8];
}

@property (nonatomic, retain) IBOutlet UITableView *tabView;

@end
