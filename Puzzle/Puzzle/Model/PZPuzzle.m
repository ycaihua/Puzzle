//
//  PZPuzzle.m
//  Puzzle

//////////////////////////////////////////////////////////////////////////////////////////
#import "PZPuzzle.h"
#import "PZTileLocation.h"
#import "PZTileImpl.h"

//////////////////////////////////////////////////////////////////////////////////////////
@interface PZPuzzle()

@property (nonatomic, strong) NSMutableArray *mutableTiles;
@property (nonatomic, assign) PZTileLocation emptyTileLocation;
@property (nonatomic, assign) PZTileLocation previousEmptyTileLocation;
@property (nonatomic, assign) BOOL previousRandomMoveWasHorizontal;

@end

//////////////////////////////////////////////////////////////////////////////////////////
@implementation PZPuzzle
@synthesize size, movesCount, mutableTiles, emptyTileLocation, previousEmptyTileLocation,
            previousRandomMoveWasHorizontal;

- (id)initWithImage:(UIImage *)anImage size:(NSUInteger)aSize
{
    if (nil != (self = [super init]))
    {
        self.mutableTiles = [[self class] newTilesWithImage:anImage size:aSize];
        self.emptyTileLocation = PZTileLocationMake(aSize - 1, aSize - 1);
        self.previousEmptyTileLocation = self.emptyTileLocation;
        self.size = aSize;
        self.movesCount = 0;
    }
    return self;
}

- (id<IPZTile>)tileAtLocation:(PZTileLocation)aLocation
{
    if (PZTileLocationEqualToLocation(self.emptyTileLocation, aLocation))
    {
        return nil;
    }
    return [self.mutableTiles objectAtIndex:[self indexOfTileAtLocation:aLocation]];
}

- (PZMoveDirection)allowedMoveDirectionForTileAtLocation:(PZTileLocation)aLocation
{
    if (PZTileLocationEqualToLocation(aLocation, self.emptyTileLocation))
    {
        // no moves for empty location
        return kNoneDirection;
    }
    if (PZTileLocationInSameColumnAsLocation(aLocation, self.emptyTileLocation))
    {
        // vertical move allowed
        return (aLocation.y < self.emptyTileLocation.y) ? kDownDirection : kUpDirection;
    }
    if (PZTileLocationInSameRowAsLocation(aLocation, self.emptyTileLocation))
    {
        // horizontal move allowed
        return (aLocation.x < self.emptyTileLocation.x) ? kRightDirection : kLeftDirection;
    }
    return kNoneDirection;
}

- (NSArray *)affectedTilesByTileMoveAtLocation:(PZTileLocation)aLocation
{
    return [self tilesAtLocations:[self affectedTilesLocationsByTileMoveAtLocation:aLocation]];
}

- (NSArray *)tilesAtLocations:(NSArray *)aLocations
{
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:aLocations.count];
    
    for (NSValue *location in aLocations)
    {
        id tile = [self tileAtLocation:[location tileLocation]];
        [result addObject:tile ? tile : [NSNull null]];    
    }
    
    return [[NSArray alloc] initWithArray:result];
}

- (NSArray *)affectedTilesLocationsByTileMoveAtLocation:(PZTileLocation)aLocation
{
    NSMutableArray *result = [NSMutableArray new];
    void(^addTileLocation)(NSUInteger, NSUInteger) = ^(NSUInteger x, NSUInteger y)
    {
        [result addObject:[[NSValue alloc] initWithTileLocation:PZTileLocationMake(x, y)]];    
    };
    
    switch ([self allowedMoveDirectionForTileAtLocation:aLocation])
    {
        case kNoneDirection:
            break;
        case kLeftDirection:          
            for (NSUInteger x = aLocation.x; self.emptyTileLocation.x < x; x--)
            {
                addTileLocation(x, aLocation.y);
            }
            break;
        case kRightDirection:          
            for (NSUInteger x = aLocation.x; x < self.emptyTileLocation.x; x++)
            {
                addTileLocation(x, aLocation.y);
            }
            break;
        case kUpDirection:          
            for (NSUInteger y = aLocation.y; self.emptyTileLocation.y < y; y--)
            {
                addTileLocation(aLocation.x, y);
            }
            break;
        case kDownDirection:
            for (NSUInteger y = aLocation.y; y < self.emptyTileLocation.y; y++)
            {
                addTileLocation(aLocation.x, y);
            }
            break;
    }
    return [[NSArray alloc] initWithArray:result];
}

- (BOOL)moveTileAtLocation:(PZTileLocation)aLocation
{
    __block PZTileLocation previousLocation = self.emptyTileLocation;
    NSArray *locations = [self affectedTilesLocationsByTileMoveAtLocation:aLocation];
    [locations enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:
    ^(id aTileLocation, NSUInteger anIndex, BOOL *aStopFlag)
    {
        PZTileLocation location = [aTileLocation tileLocation];
        [self exchangeTileAtLocation:previousLocation withTileAtLocation:location];
        previousLocation = location;
    }];
    BOOL result = nil != locations;
    if (result)
    {
        ++self.movesCount;
        self.emptyTileLocation = aLocation;
        self.previousEmptyTileLocation = self.emptyTileLocation;
    }
    return result;
}

+ (NSMutableArray *)newTilesWithImage:(UIImage *)anImage size:(NSUInteger)aSize
{
    CGFloat tileWidth = (anImage.size.width / aSize) * [UIScreen mainScreen].scale;
    CGFloat tileHeight = (anImage.size.height / aSize) * [UIScreen mainScreen].scale;

    NSUInteger tilesCount = aSize * aSize;
    NSMutableArray *result = [[NSMutableArray alloc] initWithCapacity:tilesCount];
    for (NSUInteger tileIndex = 0; tileIndex < tilesCount; tileIndex++)
    {
        PZTileLocation location = [self locationForTileAtIndex:tileIndex size:aSize];
        CGRect rect = CGRectMake(location.x * tileWidth, location.y * tileHeight,
                                 tileWidth, tileHeight);
        CGImageRef CGImage = CGImageCreateWithImageInRect([anImage CGImage], rect);
        UIImage *image = [[UIImage alloc] initWithCGImage:CGImage];
        [result addObject:[[PZTileImpl alloc] initWithImage:image currentLocation:location winLocation:location]];
    }

    return result;
}

- (PZTileLocation)locationForTileAtIndex:(NSUInteger)anIndex
{
    return [[self class] locationForTileAtIndex:anIndex size:self.size];
}

+ (PZTileLocation)locationForTileAtIndex:(NSUInteger)anIndex size:(NSUInteger)aSize
{
    NSUInteger y = anIndex / aSize;
    NSUInteger x = anIndex - y * aSize;
    
    return PZTileLocationMake(x, y);
}

- (BOOL)isWin
{
    for (NSUInteger tileIndex = 0; tileIndex < self.mutableTiles.count; tileIndex++)
    {
        PZTileImpl *tile = [self.mutableTiles objectAtIndex:tileIndex];
        if (!PZTileLocationEqualToLocation([self locationForTileAtIndex:tileIndex],
                                           tile.winLocation))
        {
            return NO;
        }
    }
    return YES;
}

- (void)exchangeTileAtLocation:(PZTileLocation)aLocation1 withTileAtLocation:(PZTileLocation)aLocation2
{
    NSUInteger tile1Index = [self indexOfTileAtLocation:aLocation1];
    NSUInteger tile2Index = [self indexOfTileAtLocation:aLocation2];
    [self.mutableTiles exchangeObjectAtIndex:tile1Index withObjectAtIndex:tile2Index];
    [[self.mutableTiles objectAtIndex:tile1Index] setCurrentLocation:aLocation1];
    [[self.mutableTiles objectAtIndex:tile2Index] setCurrentLocation:aLocation2];
}

- (void)moveTileToRandomLocationWithCompletionBlock:(void (^)(NSArray *tiles, PZMoveDirection direction))aBlock
{
    NSUInteger safetyCounter = 100;
    do 
    {
        PZTileLocation newLocation = self.previousRandomMoveWasHorizontal ?
                                    [self randomVerticalMovableTileLocation] :
                                    [self randomHorizontalMovableTileLocation];

        if (!PZTileLocationEqualToLocation(self.previousEmptyTileLocation, newLocation)) 
        {
            NSArray *tiles = [self affectedTilesByTileMoveAtLocation:newLocation];
            PZMoveDirection direction = [self allowedMoveDirectionForTileAtLocation:newLocation];
            [self moveTileAtLocation:newLocation];
            aBlock(tiles, direction);
            self.previousRandomMoveWasHorizontal = kLeftDirection == direction ||
                                                   kRightDirection == direction;
            break;
        }
        
    } while (--safetyCounter);
    self.movesCount = 0;
}

- (PZTileLocation)randomHorizontalMovableTileLocation
{
    NSUInteger randomLocation = arc4random() % self.size - 1;    
    if (self.emptyTileLocation.x <= randomLocation )
    {
        // we must take into account empty tile and skip it
        ++randomLocation;
    }
    return PZTileLocationMake(randomLocation, self.emptyTileLocation.y);
}

- (PZTileLocation)randomVerticalMovableTileLocation
{
    NSUInteger randomLocation = arc4random() % self.size - 1;
    if (self.emptyTileLocation.y <= randomLocation )
    {
        // we must take into account empty tile and skip it
        ++randomLocation;
    }
        
    return PZTileLocationMake(self.emptyTileLocation.x, randomLocation);
}

- (NSUInteger)indexOfTileAtLocation:(PZTileLocation)aLocation
{
    return aLocation.y * self.size + aLocation.x;
}

@end
