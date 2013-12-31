//
//  BESongViewController.m
//  Basic Example
//
//  Created by Scott BonAmi on 12/30/13.
//  Copyright (c) 2013 Scott BonAmi. All rights reserved.
//

#import "BESongViewController.h"

#import "AppDelegate.h"

#import "Artist.h"
#import "Song.h"
#import "Genre.h"

@interface BESongViewController ()

@end

@implementation BESongViewController

- (id)initWithArtist:(Artist *)artist
{
    self = [super init];
    if (self) {
        [self setArtist:artist];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];
    
    // Display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)setArtist:(Artist *)artist {
    if (![_artist isEqual:artist]) {
        _artist = artist;
        
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return ([self.artist.artistSongs count]>0)?1:0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.artist.artistSongs count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    Song *rowSong = [[self.artist.artistSongs allObjects] objectAtIndex:indexPath.row];
    
    // Configure the cell...
    [cell.textLabel setText:rowSong.songTitle];
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"Genre: %@",rowSong.songGenre.genreName]];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Song *rowSong = [[self.artist.artistSongs allObjects] objectAtIndex:indexPath.row];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Song Information"
                                                    message:[NSString stringWithFormat:@"Song: %@\nArtist: %@\nGenre: %@",rowSong.songTitle, rowSong.songArtist.artistName, rowSong.songGenre.genreName]
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:@"OK", nil];
    [alert show];
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}

// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        Song *rowSong = [[self.artist.artistSongs allObjects] objectAtIndex:indexPath.row];
        [rowSong.managedObjectContext deleteObject:rowSong];
        [rowSong.managedObjectContext save:nil];
        [self.tableView reloadData];
    }
}

@end