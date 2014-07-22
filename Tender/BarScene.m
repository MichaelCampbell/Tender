//
//  BarScene.m
//  Tender
//
//  Created by Yuraima Estevez on 4/29/14.
//  Copyright (c) 2014 Yuraima Estevez. All rights reserved.
//

#import "BarScene.h"



@interface BarScene()

// Private Properties

// Timer Properties
@property (nonatomic) BOOL startFlag;
@property (nonatomic) BOOL unpause;
@property (nonatomic) BOOL isPaused;
@property (nonatomic) NSTimeInterval startTime;
@property (nonatomic) NSTimeInterval pausedTime;
@property (nonatomic) NSTimeInterval startPause;
@property (nonatomic) NSTimeInterval pauseStart;
@property (nonatomic) NSTimeInterval pauseEnd;
@property (nonatomic) NSTimeInterval runningTime;
@property (nonatomic) NSTimeInterval gameTime;

// Game Properties
@property (nonatomic) BOOL gameOver;
@property (nonatomic) BOOL activeOrder;
@property (nonatomic) BOOL drinkInQue;

@property (nonatomic) CGFloat randomXPosition;
@property (strong, nonatomic) NSMutableArray *strikes;                                        // Number of Lives
@property (strong, nonatomic) NSMutableArray *drinksInScene;
@property (strong, nonatomic) NSMutableString *tappedItemName;

// Private Methods
- (CGFloat) newRandomPosition;
- (void) createBarItems;
- (void) randomOrder;

- (void) checkVelocity;
- (void) checkForMatchWithDrink:(DrinkNode *)drink;
- (void)slideDrink:(DrinkNode *)drink WithXVelocity:(CGFloat)xVelocity;
- (void) removeActiveOrder: (Order *)order Drink: (DrinkNode *)drink;

- (void) updateGameScoreWithPoints: (NSInteger)points;
- (void) displayPointsEarnedForDrink: (DrinkNode *)drink WithPoints:(NSInteger)points;

- (void) endGame;

@end

@implementation BarScene

// CONSTANT VALUES

const CGFloat VELOCITY_SCALE = 15000;
const CGFloat BAR_ITEM_SCALE = 0.70;
const CGFloat SCENE_SCALE = 0.50;
const CGFloat STRIKE_SCALE = 0.25;
const CGFloat BUBBLE_ITEM_SCALE = 0.30;


const CGFloat MIN_VELOCITY = 1;

const CGFloat DRINK_X = 50;
const CGFloat DRINK_Y = 110;
const CGFloat ANCHOR_X = 0.5;
const CGFloat ANCHOR_Y = 0.0;
const CGFloat BAR_BASE_Y = 12;
const CGFloat BAR_BASE_X = 75;
const CGFloat BUBBLE_Y = 260;

const NSInteger RANDOM_BASE_POSITION = 150;
const NSInteger RANDOM_MAX_POSITION = 500;
const CGFloat TIER_1_POSITION = 75;
const CGFloat TIER_2_POSITION = 40;
const CGFloat TIER_3_POSITION = 10;
const CGFloat SCORE_X = 550;
const CGFloat SCORE_Y = 30;

const NSInteger ITEMS_COUNT = 4;

const CGFloat BAR_ITEM_SPACE = 100;
const CGFloat BACKGROUND_OFFSET = 60;
const CGFloat BAR_OFFSET = 100;
const CGFloat ITEM_FOUR_OFFSET = 25;

const NSInteger STRIKES_NUM = 4;

////////////////////
// INITIALIZATION //
////////////////////
#pragma mark - INITIALIZATION

- (id) initWithSize:(CGSize)size
{
    if (self = [super initWithSize:size]) {
        self.backgroundColor = [SKColor whiteColor];
        
        // Initialize score with zero
        _gameScore = 0;
        _drinkInQue = NO;
        _activeOrder = NO;
        
        // Timer flag
        _startFlag = YES;
        _pausedTime = 0;
        _gameTime = 120;
        
        // Configuring physics world with no gravity
        self.physicsWorld.gravity = CGVectorMake(0, 0);
        
        [self createSceneContents];
    }
    return self;
}

- (NSMutableArray *) drinksInScene {
    if (!_drinksInScene) {
        _drinksInScene = [NSMutableArray array];
    }
    return _drinksInScene;
}
- (void) createSceneContents
{
    self.backgroundColor = [SKColor blackColor];
    self.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:self.frame];
    
    // Setting up background sprite
    SKSpriteNode *background = [SKSpriteNode spriteNodeWithImageNamed:@"background.png"];
    background.userInteractionEnabled = NO;
    background.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
    
    SKSpriteNode *bar = [SKSpriteNode spriteNodeWithImageNamed:@"bar.png"];
    bar.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame) - BAR_OFFSET);
    bar.physicsBody = [[SKPhysicsBody alloc]init];
    bar.physicsBody.friction = 0.36;
    bar.userInteractionEnabled = NO;
    
    // Countdown Timer
    self.timer = [[SKLabelNode alloc]initWithFontNamed:@"Half Bold Pixel-7"];
    self.timer.fontSize = 15;
    self.timer.position = CGPointMake(400, 300);  //change later
    self.timer.name = @"timer";
    
    
    self.pauseButton = [[SKLabelNode alloc]initWithFontNamed:@"Half Bold Pixel-7"];
    self.pauseButton.fontSize = 15;
    self.pauseButton.position = CGPointMake(450, 300);
    self.pauseButton.name = @"pauseButton";
    
    SKLabelNode *quitNode = [SKLabelNode labelNodeWithFontNamed:@"Half Bold Pixel-7"];
    quitNode.text = @"Quit...";
    quitNode.fontSize = 12;
    quitNode.position = CGPointMake(20, 10);
    quitNode.name = @"quitNode";
    
    [self addChild:background];
    [self addChild:bar];
    [self createBarItems];
    [self randomOrder];
    [self addScoreLabel];
    [self addStrikes];
    
    // adding timer
    [self addChild:self.timer];
    [self addChild:quitNode];
    [self addChild:self.pauseButton];
    
    
}

- (void)didMoveToView:(SKView *)view
{
    // Adding gesture recognizer for drink
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
    [[self view] addGestureRecognizer:panRecognizer];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(handleTap:)];
    [[self view] addGestureRecognizer:tapRecognizer];
}

- (NSMutableArray *) strikes
{
    if (!_strikes) {
        _strikes = [[NSMutableArray alloc]init];
    }
    return _strikes;
}


- (CGFloat) newRandomPosition
{
    _randomXPosition = (CGFloat)((arc4random() % (int)self.size.width) + RANDOM_BASE_POSITION);
    
    if (_randomXPosition > 500) {
        _randomXPosition = [self newRandomPosition];
    }
    
    return _randomXPosition;
}


////////////////////
// SCENE CONTENTS //
////////////////////
#pragma mark - SCENE CONTENTS

- (void) addDrinkWithName:(NSString *)name {
    DrinkNode *drink = [[DrinkNode alloc]initWithImageNamed:name];
    drink.position = CGPointMake(DRINK_X, DRINK_Y);
    drink.anchorPoint = CGPointMake(0.5, 0.0);
    drink.inQueue = YES;
    self.drinkInQue = YES;
    
    if ([drink isKindOfClass:[DrinkNode class]]) {
        NSLog(@"%@", drink.inQueue ? @"in queue" : @"not");
        [self.drinksInScene addObject:drink];
        NSLog(@"%@", self.drinksInScene);

    }
    
    [self addChild:drink];
}

- (void) addScoreLabel
{
    self.scoreLabel = [[SKLabelNode alloc]initWithFontNamed:@"Half Bold Pixel-7"];
    self.scoreLabel.name = @"scoreLabel";
    self.scoreLabel.text = @"$0";
    self.scoreLabel.fontSize = 15;
    self.scoreLabel.position = CGPointMake(SCORE_X, SCORE_Y);
    
    [self updateGameScoreWithPoints:0];
    
    [self addChild:self.scoreLabel];
}

- (void) randomOrder
{
    CGPoint position = CGPointMake([self newRandomPosition], BUBBLE_Y);
    NSInteger randNum = arc4random() % 4;
    
    SKSpriteNode *order = (SKSpriteNode *)[[Order alloc]initWithItemNamed:[NSString stringWithFormat:@"orderItem%ld", (long)randNum]];
    order.position = position;
    
    [self.activeOrders addObject:order];
    [self addChild:order];
    
    
}

- (void) createBarItems
{
    for (NSInteger i = 0; i <= ITEMS_COUNT; i++) {
        NSString *name = [NSString stringWithFormat:@"%ld", (long)i];
        SKSpriteNode *item = [[SKSpriteNode alloc]initWithImageNamed:[NSString stringWithFormat:@"barItem%@.png", name]];
        item.name = name;
        item.anchorPoint = CGPointMake(ANCHOR_X, ANCHOR_Y);
        item.userInteractionEnabled = YES;
    
        if (i == 0) {
            item.position = CGPointMake(BAR_BASE_X, BAR_BASE_Y);
        }
        else {
            item.position = CGPointMake(BAR_BASE_X + (BAR_ITEM_SPACE * i), BAR_BASE_Y);
            if ([item.name  isEqual: @"item4"]) {
                item.position = CGPointMake(BAR_BASE_X + (BAR_ITEM_SPACE * i), ITEM_FOUR_OFFSET);
            }
        }
        [self addChild:item];
    }
}

- (void) addStrikes
{
    for (NSInteger i = 0; self.strikes.count <= STRIKES_NUM; i++) {
        [self.strikes addObject:[[SKSpriteNode alloc]initWithImageNamed:@"item0.png"]];
        SKSpriteNode *strike = (SKSpriteNode *)self.strikes[i];
        strike.position = CGPointMake(125 + (i*20), 305);
        [strike setScale:STRIKE_SCALE];
        [self addChild:strike];
    }
}

- (void) removeStrike
{
    [[self.strikes lastObject] removeFromParent];
    [self.strikes removeLastObject];
}


/////////////////////////
// GESTURE RECOGNIZERS //
/////////////////////////
#pragma mark - GESTURE RECOGNIZERS

- (void) handlePan: (UIPanGestureRecognizer*)recognizer
{
    
    SKNode *touchedNode;
    DrinkNode *drink;
    
    if (recognizer.state == UIGestureRecognizerStateBegan && self.drinkInQue) {
        CGPoint beganLocation = [recognizer locationInView:recognizer.view];
        beganLocation = [self convertPointFromView:beganLocation];
        touchedNode = [self nodeAtPoint:beganLocation];
    }
    
    if ([touchedNode isKindOfClass:[DrinkNode class]]) {
        drink = (DrinkNode *) touchedNode;
    }
    
    if (drink.isInQueue) {
        NSLog(@"drink in queue: %@", drink);
        
            CGFloat recognizerVelocity = [recognizer velocityInView:self.view].x;
            NSLog(@"recognizer velocity %f", recognizerVelocity);
            [self slideDrink:drink WithXVelocity:recognizerVelocity];
            drink.inMotion = YES;
            
            self.drinkInQue = NO;
        
    }
}

- (void) handleTap: (UITapGestureRecognizer *)recognizer
{
    if (recognizer.state == UIGestureRecognizerStateEnded &&
        self.scene.view.paused != YES)
    {
        // Adding gesture recognizer to node at touch point
        CGPoint touchLocation = [recognizer locationInView:recognizer.view];
        touchLocation = [self convertPointFromView:touchLocation];
        
        if ((touchLocation.x >= 0 && touchLocation.x <= 30) && (touchLocation.y >= 0 && touchLocation.y <= 30)) {
            [self backToStart];
        } else if ((touchLocation.x >= 440 && touchLocation.x <= 460 ) && (touchLocation.y >= 280 && touchLocation.y <= 320)) {
            [self pauseGame];
        } else {
            if (self.drinkInQue == NO) {
                SKSpriteNode *touchedNode = (SKSpriteNode *)[self nodeAtPoint:touchLocation];
                if (touchedNode.userInteractionEnabled == YES) {
                    [self addDrinkWithName:[NSString stringWithFormat:@"item%@",touchedNode.name]];
                }
            }
            
        }
        
    } else if (self.scene.view.paused == YES) {
        [self pauseGame];
    }
}

//////////////////
// UPDATE SCENE //
//////////////////
#pragma mark - UPDATE SCENE

- (void)update:(NSTimeInterval)currentTime
{
    // Change pause label
    if (self.scene.paused == NO) {
        self.pauseButton.text = @"||";
    } else {
        self.pauseButton.text = @"►";
    }
    
    // Call if isInMotion is true
    if (self.drinksInScene.count != 0) {
        [self checkVelocity];
    }
    
    if ([self childNodeWithName:@"drink"].position.x > self.size.width) {
        SKAction *glassBreakSound = [SKAction playSoundFileNamed:@"glassBreaking.wav" waitForCompletion:NO];
        [[self nodeAtPoint:CGPointMake(CGRectGetMaxX(self.view.frame), DRINK_Y)] removeFromParent];
        [self runAction:glassBreakSound];
        [self removeStrike];
    }
    
    // Updating timer
    if (self.startFlag) {
        self.startTime = currentTime;
        self.startFlag = NO;
    }
    
    // Checking for pause times
    if (self.startPause) {
        self.pauseStart = currentTime;
        self.startPause = NO;
    }
    if (self.unpause) {
        self.pauseEnd = currentTime;
        self.unpause = NO;
    }
    
    if (self.pauseEnd != 0) {
        self.pausedTime += (self.pauseEnd - self.pauseStart);
        self.pauseEnd = 0;
    }
    self.runningTime = (currentTime - self.startTime) - self.pausedTime;
    
    if (!self.gameOver && !self.scene.paused) {
        if ([self updateTimerWithCurrentTime:currentTime]) {
            [[self childNodeWithName:@"pauseButton"] removeFromParent];
            [self endGame];
        }
    }
}

- (BOOL) updateTimerWithCurrentTime: (NSTimeInterval)currentTime {
    
    NSDateFormatter *df = [[NSDateFormatter alloc]init];
    [df setDateFormat:@"mm:ss"];
    
    
    NSString *formattedTimer = [df stringFromDate:[NSDate dateWithTimeIntervalSinceReferenceDate:(self.gameTime - self.runningTime)]];
    self.timer.text = [NSString stringWithFormat:@"%@", formattedTimer];
    
    if ([self.timer.text isEqualToString:@"00:00"] ) {
        self.gameOver = YES;
    }
    
    return self.gameOver;
}

- (void) pauseGame {
    
    if (self.scene.view.paused == NO) {
        SKAction *flag = [SKAction runBlock:^{
            self.startPause = YES;
        }];
        SKAction *delay = [SKAction waitForDuration:0.1];
        SKAction *pauseIt = [SKAction runBlock:^{
            self.scene.view.paused = YES;
        }];
        
        SKAction *sequence = [SKAction sequence:@[flag, delay, pauseIt]];
        [self runAction:sequence];
        
        SKSpriteNode *pauseBG = [[SKSpriteNode alloc]initWithColor:[UIColor colorWithRed:138/255.0f green:181/255.0f blue:189/255.0f alpha:0.5] size:self.view.bounds.size];
        pauseBG.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        pauseBG.name = @"pauseBG";
        
        SKLabelNode *pausedLabel = [[SKLabelNode alloc]initWithFontNamed:@"Half Bold Pixel-7"];
        pausedLabel.text = @"PAUSED";
        pausedLabel.fontSize = 30;
        pausedLabel.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame));
        pausedLabel.name = @"pauseViewLabel";
        
        SKLabelNode *resumelabel = [[SKLabelNode alloc]initWithFontNamed:@"Half Bold Pixel-7"];
        resumelabel.text = @"Tap screen to resume";
        resumelabel.fontSize = 15;
        resumelabel.position = CGPointMake(pausedLabel.position.x, pausedLabel.position.y - 20);
        resumelabel.name = @"resumeLabel";
        
        [self addChild:pauseBG];
        [self addChild:pausedLabel];
        [self addChild:resumelabel];
        
        
    } else {
        self.unpause = YES;
        self.scene.view.paused = NO;
        [[self childNodeWithName:@"pauseBG"] removeFromParent];
        [[self childNodeWithName:@"pauseViewLabel"] removeFromParent];
        [[self childNodeWithName:@"resumeLabel"] removeFromParent];
    }
}


///////////////////////////
// VELOCITY AND POSITION //
///////////////////////////
#pragma mark - VELOCITY AND POSITION

- (void)slideDrink:(DrinkNode *)drink WithXVelocity:(CGFloat)xVelocity
{
    NSLog(@"Sliding...");
    CGFloat slideVelocity = (xVelocity * 5);
    NSLog(@"slide velocity: %f", slideVelocity);
    [drink.physicsBody applyImpulse:CGVectorMake(slideVelocity, 0)];
    drink.inQueue = NO;
}

-(void) checkVelocity
{

    for (SKNode *sprite in [self children]) {
        if ([sprite.name isEqualToString:@"drink"]) {
            DrinkNode *drink = (DrinkNode *) sprite;
            NSLog(@"velocity:%f",drink.physicsBody.velocity.dx);
            if (drink.isInMotion && drink.physicsBody.velocity.dx < MIN_VELOCITY) {
                [self checkForMatchWithDrink:drink];
            }
        }
    }
    
}

-(void)checkForMatchWithDrink:(DrinkNode *)drink
{
    NSInteger earnedPoints = 0;
    
    for (Order *order in self.activeOrders) {
        if ([order.item isEqualToString:drink.item]) {
            if ((drink.position.x >= (order.position.x - TIER_1_POSITION)) &&
                (drink.position.x <= order.position.x + TIER_1_POSITION)) {
                
                    earnedPoints++;
                    
                    if ((drink.position.x >= order.position.x - TIER_2_POSITION) &&
                        (drink.position.x <= order.position.x + TIER_2_POSITION)) {
                        earnedPoints += 4;
                        
                        if ((drink.position.x >= order.position.x - TIER_3_POSITION) &&
                            (drink.position.x <= order.position.x + TIER_3_POSITION)) {
                            earnedPoints += 5;
                        }
                    }
            }
        } else {
            earnedPoints = 0;
            [self removeStrike];
        }
        
        [self removeActiveOrder:order Drink:drink];
    }
    
    [self updateGameScoreWithPoints:earnedPoints];
    [self displayPointsEarnedForDrink:drink WithPoints:earnedPoints];
    
    if (self.strikes.count == 0) {
        [self endGame];
    }

}

- (void) removeActiveOrder: (Order *)order Drink: (DrinkNode *)drink{
    
    SKAction *fadeOut = [SKAction fadeOutWithDuration:1];
    SKAction *fadeBlock = [SKAction runBlock:^{
        [order runAction:fadeOut];
    }];
    SKAction *delay = [SKAction waitForDuration:2.0];
    SKAction *newOrder = [SKAction runBlock:^{
        [self newRandomPosition];
    }];
    SKAction *sequence = [SKAction sequence:@[fadeBlock, delay, newOrder]];
    
    [self runAction:sequence];
    
    [drink runAction:fadeOut completion:^(void){
        [drink removeFromParent];
        [self.drinksInScene removeObject:drink];
    }];
    
    [self performSelector:@selector(randomOrder) withObject:self afterDelay:2.0];
    
}

//////////////////////
// SCORE AND POINTS //
//////////////////////
#pragma mark - SCORE AND POINTS

- (void) updateGameScoreWithPoints: (NSInteger)points
{
    self.gameScore += points;
    self.scoreLabel.text = [NSString stringWithFormat:@"$%ld",(long)self.gameScore];
    
    if (self.gameScore > 0) {
        self.scoreLabel.fontColor = [SKColor greenColor];
    }
    else{
        self.scoreLabel.fontColor = [SKColor redColor];
    }
}


- (void) displayPointsEarnedForDrink: (DrinkNode *)drink WithPoints:(NSInteger)points
{
    SKLabelNode *pointsLabel = [[SKLabelNode alloc]initWithFontNamed:@"Half Bold Pixel-7"];
    
    // Absolute value of points labs()
    pointsLabel.text = [NSString stringWithFormat:@"$%ld",labs((long)points)];
    pointsLabel.fontSize = 15;
    pointsLabel.position = CGPointMake(drink.position.x, drink.position.y + 30);
    pointsLabel.name = @"pointsLabel";
    
    // setting font color based on negative/positive points
    if (points > 0) {
        pointsLabel.fontColor = [UIColor greenColor];
    } else {
        pointsLabel.fontColor = [UIColor redColor];
    }
    
    // floating animation for label
    SKAction *fade = [SKAction sequence:@[[SKAction fadeInWithDuration:0.5],
                                          [SKAction fadeOutWithDuration:0.5]]];
    
    // Sound Effect
    SKAction *pointsSound;
    if (points > 0) {
        pointsSound = [SKAction playSoundFileNamed:@"cashRegister.mp3" waitForCompletion:NO];
    } else {
        pointsSound = [SKAction playSoundFileNamed:@"oi.mp3" waitForCompletion:NO];
    }

    // move up by Y
    SKAction *moveUp = [SKAction moveByX:0 y:10 duration:1.0];
    
    // adding to action group
    SKAction *floatGroup = [SKAction group:@[moveUp, fade, pointsSound]];
    
    // add to scene
    [self addChild:pointsLabel];
    
    // Running Action with completion block
    [pointsLabel runAction:floatGroup completion:^(void){
        // Removing node from screen upon completion
        [pointsLabel removeFromParent];
    }];
    
}

////////////////
// GAME OVER/ //
////////////////
#pragma mark - GAME OVER

- (void) endGame {
    GameOverScene *gameOverScene = [[GameOverScene alloc]initWithSize:self.size Score:self.gameScore];
    [self.view presentScene:gameOverScene transition:[SKTransition doorsCloseVerticalWithDuration:2.0]];

}

- (void) backToStart {
    StartScene *start = [[StartScene alloc] initWithSize:self.size];
    [self.view presentScene:start transition:[SKTransition doorsCloseHorizontalWithDuration:1]];
}

@end
