//
//  BERootViewController.m
//  Basic Example
//
//  Created by Scott BonAmi on 12/27/13.
//  Copyright (c) 2013 Scott BonAmi. All rights reserved.
//

#import "AppDelegate.h"
#import "BERootViewController.h"
#import "BESongViewController.h"
#import "PFIncrementalStore.h"

#import "Artist.h"
#import "Song.h"
#import "Genre.h"

@interface BERootViewController () <NSFetchedResultsControllerDelegate>{
    NSManagedObjectContext *context;
}
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@end

@implementation BERootViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    context = [appDelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Artist"];
    NSSortDescriptor *sortByName = [NSSortDescriptor sortDescriptorWithKey:@"artistName" ascending:YES];
    fetchRequest.sortDescriptors = @[sortByName];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:context
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    
    NSError *error = nil;
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:&error];
    
    // Display an Edit button in the navigation bar for this view controller.
    self.navigationItem.rightBarButtonItem = self.editButtonItem;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addObject:)];
    
    //refresh controller
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(refetchData) forControlEvents:UIControlEventValueChanged];
    [[NSNotificationCenter defaultCenter] addObserverForName:PFIncrementalStoreContextDidFetchRemoteValues
                                                      object:nil queue:[NSOperationQueue mainQueue]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self.refreshControl endRefreshing];
                                                  }];
    
}

#pragma mark - UI Event
- (IBAction)addObject:(id)sender{
    Artist *artist = [NSEntityDescription insertNewObjectForEntityForName:@"Artist" inManagedObjectContext:context];
    Song *song = [NSEntityDescription insertNewObjectForEntityForName:@"Song" inManagedObjectContext:context];
    Genre *genre = [NSEntityDescription insertNewObjectForEntityForName:@"Genre" inManagedObjectContext:context];
    artist.artistName = [NSString stringWithFormat:@"user_%d", arc4random_uniform(100)];
    genre.genreName = [NSString stringWithFormat:@"genre_%d", arc4random_uniform(100)];
    song.songTitle = [NSString stringWithFormat:@"song_%d", arc4random_uniform(100)];
    song.songArtist = artist;
    song.songGenre = genre;
    NSError *err;
    [context save:&err];
    if (err) {
        NSLog(@"%@", err.description);
    }
}

- (void)refetchData{
    _fetchedResultsController.fetchRequest.resultType = NSManagedObjectResultType;
    [_fetchedResultsController performFetch:nil];
}

#pragma mark - NSFetchedResultsControllerDelegate

-(void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id <NSFetchedResultsSectionInfo>)sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)object atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    switch(type) {
        case NSFetchedResultsChangeInsert:
            if (!newIndexPath) return;
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeUpdate:
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
        case NSFetchedResultsChangeMove:
            if (!newIndexPath) return;
            [self.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            [self.tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
            break;
    }
}

-(void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self.tableView endUpdates];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return [[self.fetchedResultsController sections] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    id <NSFetchedResultsSectionInfo> tableSection = [[self.fetchedResultsController sections] objectAtIndex:section];
    return [tableSection numberOfObjects];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    // If there are no reusable cells; create new one
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    id <NSFetchedResultsSectionInfo> tableSection = [[self.fetchedResultsController sections] objectAtIndex:indexPath.section];
    Artist *rowArtist = [[tableSection objects] objectAtIndex:indexPath.row];
    
    // Configure the cell...
    [cell.textLabel setText:rowArtist.artistName];
    NSSet *songs = rowArtist.artistSongs;
    [cell.detailTextLabel setText:[NSString stringWithFormat:@"Number of Songs: %lu",(unsigned long)songs.count]];
    
    return cell;
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
        id <NSFetchedResultsSectionInfo> tableSection = [[self.fetchedResultsController sections] objectAtIndex:indexPath.section];
        Artist *rowArtist = [[tableSection objects] objectAtIndex:indexPath.row];
        for (Song *s in rowArtist.artistSongs) {
            [context deleteObject:s.songGenre];
            [context deleteObject:s];
        }
        [context deleteObject:rowArtist];
        [context save:nil];
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    id <NSFetchedResultsSectionInfo> tableSection = [[self.fetchedResultsController sections] objectAtIndex:indexPath.section];
    Artist *rowArtist = [[tableSection objects] objectAtIndex:indexPath.row];
    
    BESongViewController *vcSongTableView = [[BESongViewController alloc] initWithArtist:rowArtist];
    [self.navigationController pushViewController:vcSongTableView animated:YES];
}

@end
