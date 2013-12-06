//
//  JLTMultiSwitch.m
//  JLTMultiSwitch
//
//  Created by Jeffery Thomas on 10/4/13.
//  Copyright (c) 2013 JLTSource. No rights reserved. Do with it what you will.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "JLTMultiSwitch.h"
#import <tgmath.h>

@interface JLTMultiSwitch ()
@property (nonatomic) UIView *JLT_positionViewsContainer;
@property (nonatomic) CGFloat JLT_xOffset;
@property (nonatomic) BOOL JLT_awake;
@end

@implementation JLTMultiSwitch

- (void)setCurrentPosition:(NSUInteger)currentPosition animated:(BOOL)animated
{
    CGFloat knobX = [self JLT_knobXFromPosition:currentPosition];
    CGFloat positionViewsContainerX = [self JLT_positionViewsContainerXFromKnobX:knobX];

    BOOL wasSet = [self isSet];
    _currentPosition = currentPosition;
    BOOL isSet = [self isSet];

    if (!animated) {
        [self JLT_ajustKnobViewToX:knobX];
        [self JLT_ajustPositionViewsContainerToX:positionViewsContainerX];
        [self JLT_ajustUnsetViewToIsSet:[self isSet]];
    } else if (!wasSet || !isSet) {
        [self JLT_ajustKnobViewToX:knobX];
        [self JLT_ajustPositionViewsContainerToX:positionViewsContainerX];
        [UIView animateWithDuration:0.075 animations:^{
            [self JLT_ajustUnsetViewToIsSet:[self isSet]];
        }];
    } else {
        [UIView animateWithDuration:0.25 animations:^{
            [self JLT_ajustKnobViewToX:knobX];
            [self JLT_ajustPositionViewsContainerToX:positionViewsContainerX];
            [self JLT_ajustUnsetViewToIsSet:[self isSet]];
        }];
    }
}

- (BOOL)isSet
{
    return self.currentPosition != JLTMultiSwitchUnset;
}

#pragma mark UIView

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.JLT_awake = YES;

    [self JLT_setup];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesBegan:touches withEvent:event];
    CGFloat x = [[touches anyObject] locationInView:self].x;
    CGFloat width = self.bounds.size.width/[self.positionViews count];
    self.JLT_xOffset = x - ((width * (CGFloat)[self JLT_positionFromX:x]) + width/2);

    CGFloat knobX = [self JLT_knobXFromX:x - self.JLT_xOffset];

    if (![self isSet]) {
        [UIView animateWithDuration:0.075 animations:^{
            [self JLT_ajustUnsetViewToIsSet:YES];
        }];
    }

    [self JLT_ajustKnobViewToX:knobX];
    [self JLT_ajustPositionViewsContainerToX:[self JLT_positionViewsContainerXFromKnobX:knobX]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesMoved:touches withEvent:event];
    CGFloat x = [[touches anyObject] locationInView:self].x;
    CGFloat knobX = [self JLT_knobXFromX:x - self.JLT_xOffset];

    [self JLT_ajustKnobViewToX:knobX];
    [self JLT_ajustPositionViewsContainerToX:[self JLT_positionViewsContainerXFromKnobX:knobX]];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesEnded:touches withEvent:event];
    CGFloat x = [[touches anyObject] locationInView:self].x;

    NSUInteger position = [self JLT_positionFromX:x - self.JLT_xOffset];

    if (position != self.currentPosition) {
        [self setCurrentPosition:position animated:YES];
        [self sendActionsForControlEvents:UIControlEventValueChanged];
    } else {
        [self setCurrentPosition:position animated:YES];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];
    [self setCurrentPosition:self.currentPosition animated:YES];
}

#pragma mark Private

- (void)JLT_setup
{
    if (!self.JLT_awake)
        return;

    CGRect bounds = self.bounds;

    CGRect frame = bounds;
    frame.size.width = frame.size.width * [self.positionViews count];
    self.JLT_positionViewsContainer.frame = frame;

    [self.positionViews enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        UIView *view = obj;

        CGRect frame = bounds;
        frame.origin.x = frame.size.width * idx;
        view.frame = frame;

        [self.JLT_positionViewsContainer addSubview:view];
    }];

    self.unsetView.frame = bounds;

    [self addSubview:self.JLT_positionViewsContainer];
    [self addSubview:self.knobView];
    [self addSubview:self.unsetView];

    self.currentPosition = self.currentPosition;
}

- (CGFloat)JLT_knobXFromX:(CGFloat)x
{
    CGFloat knobX = x - (self.knobView.frame.size.width/2.0);
    CGFloat minX = 0.0;
    CGFloat maxX = self.bounds.size.width - self.knobView.frame.size.width;

    return knobX < maxX ? knobX > minX ? knobX : minX : maxX;
}

- (CGFloat)JLT_knobXFromPosition:(NSUInteger)position
{
    if (position == JLTMultiSwitchUnset) return NAN;

    CGFloat knobwidth = self.knobView.frame.size.width;
    CGFloat width = self.bounds.size.width;

    return position * (width - knobwidth) / ([self.positionViews count] - 1);
}

- (NSUInteger)JLT_positionFromX:(CGFloat)x
{
    if (isnan(x)) return JLTMultiSwitchUnset;

    CGFloat width = self.bounds.size.width / [self.positionViews count];

    return MIN(MAX(0, floor(x / width)), [self.positionViews count] - 1);
}

- (CGFloat)JLT_positionViewsContainerXFromKnobX:(CGFloat)knobX
{
    if (isnan(knobX)) return NAN;

    CGFloat knobwidth = self.knobView.frame.size.width;
    CGFloat width = self.bounds.size.width;

    return -((knobX / (width - knobwidth) * ([self.positionViews count] - 1)) * self.bounds.size.width);
}

- (void)JLT_ajustKnobViewToX:(CGFloat)x
{
    if (isnan(x)) return;

    CGRect frame = self.knobView.frame;
    frame.origin.x = x;
    self.knobView.frame = frame;
}

- (void)JLT_ajustPositionViewsContainerToX:(CGFloat)x
{
    if (isnan(x)) return;

    CGRect frame = self.JLT_positionViewsContainer.frame;
    frame.origin.x = x;
    self.JLT_positionViewsContainer.frame = frame;
}

- (void)JLT_ajustUnsetViewToIsSet:(BOOL)visibility
{
    self.unsetView.alpha = visibility ? 0.0 : 1.0;
}

- (BOOL)JLT_areAllSubviews:(NSArray *)subviews
{
    return NSNotFound == [subviews indexOfObjectPassingTest:^BOOL(id obj, NSUInteger idx, BOOL *stop) {
        UIView *view = obj;

        return view.superview != self;
    }];
}

#pragma mark Properties

- (void)setCurrentPosition:(NSUInteger)currentPosition
{
    [self setCurrentPosition:currentPosition animated:NO];
}

- (void)setKnobView:(UIView *)knobView
{
    _knobView = knobView;

    [self JLT_setup];
}

- (void)setPositionViews:(NSArray *)segmentViews
{
    if ([self JLT_areAllSubviews:segmentViews]) {
        _positionViews = [segmentViews sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSUInteger idx1 = [self.subviews indexOfObject:obj1];
            NSUInteger idx2 = [self.subviews indexOfObject:obj2];

            return idx1 <= idx2 ? idx1 < idx2 ? NSOrderedAscending : NSOrderedSame : NSOrderedDescending;
        }];
    } else {
        _positionViews = [segmentViews copy];
    }

    [self JLT_setup];
}

@synthesize unsetView = _unsetView;

- (UIView *)unsetView
{
    if (!_unsetView) {
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
        label.backgroundColor = [UIColor lightGrayColor];

        _unsetView = label;

        [self JLT_setup];
    }
    return _unsetView;
}

- (void)setUnsetView:(UIView *)noSegmentView
{
    _unsetView = noSegmentView;

    [self JLT_setup];
}

- (UIView *)JLT_positionViewsContainer
{
    if (!_JLT_positionViewsContainer) {
        UIView *view = [[UIView alloc] initWithFrame:CGRectZero];
        _JLT_positionViewsContainer = view;
    }
    return _JLT_positionViewsContainer;
}

#pragma mark Memory lifecycle

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _JLT_awake = YES;
        _currentPosition = JLTMultiSwitchUnset;
        self.clipsToBounds = YES;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        _currentPosition = JLTMultiSwitchUnset;
        self.clipsToBounds = YES;
    }
    return self;
}

@end
