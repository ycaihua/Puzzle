//
//  PZHelpViewController.h
//  Puzzle
//
//  Created by Eugene But on 10/10/12.
//
//

//////////////////////////////////////////////////////////////////////////////////////////
#import <UIKit/UIKit.h>

//////////////////////////////////////////////////////////////////////////////////////////
@protocol PZHelpViewControllerDelegate;

//////////////////////////////////////////////////////////////////////////////////////////
@interface PZHelpViewController : UIViewController

@property (nonatomic, assign) id<PZHelpViewControllerDelegate> delegate;

@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UIButton *hideButton;

- (IBAction)hide;
- (IBAction)beginTutorial:(UIButton *)sender;

@end

//////////////////////////////////////////////////////////////////////////////////////////
@protocol PZHelpViewControllerDelegate

- (void)helpViewControllerWantsHide:(PZHelpViewController *)aController;
- (void)helpViewControllerSolvePuzzle:(PZHelpViewController *)aController completionBlock:(void(^)(void))aBlock;

@end