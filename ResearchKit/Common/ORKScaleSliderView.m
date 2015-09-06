/*
 Copyright (c) 2015, Apple Inc. All rights reserved.
 Copyright (c) 2015, Ricardo Sánchez-Sáez.
 Copyright (c) 2015, Bruce Duncan.

 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */


#import "ORKScaleSliderView.h"
#import "ORKScaleSlider.h"
#import "ORKScaleRangeLabel.h"
#import "ORKScaleRangeDescriptionLabel.h"
#import "ORKScaleValueLabel.h"
#import "ORKScaleRangeImageView.h"
#import "ORKSkin.h"


// #define LAYOUT_DEBUG 1

@implementation ORKScaleSliderView {
    id<ORKScaleAnswerFormatProvider> _formatProvider;
    ORKScaleSlider *_slider;
    ORKScaleRangeDescriptionLabel *_leftRangeDescriptionLabel;
    ORKScaleRangeDescriptionLabel *_rightRangeDescriptionLabel;
    UIView *_leftRangeView;
    UIView *_rightRangeView;
    ORKScaleValueLabel *_valueLabel;
}

- (instancetype)initWithFormatProvider:(id<ORKScaleAnswerFormatProvider>)formatProvider {
    self = [self initWithFrame:CGRectZero];
    if (self) {
        _formatProvider = formatProvider;
        
        self.slider.textChoices = [formatProvider textChoices];
        
        if ([formatProvider minimumImage]) {
            _leftRangeView = [[ORKScaleRangeImageView alloc] initWithImage:[formatProvider minimumImage]];
        } else {
            ORKScaleRangeLabel *leftRangeLabel = [[ORKScaleRangeLabel alloc] initWithFrame:CGRectZero];
            leftRangeLabel.textAlignment = NSTextAlignmentCenter;
            leftRangeLabel.text = [formatProvider localizedStringForNumber:[formatProvider minimumNumber]];
            _leftRangeView = leftRangeLabel;
        }
        
        if ([formatProvider maximumImage]) {
            _rightRangeView = [[ORKScaleRangeImageView alloc] initWithImage:[formatProvider maximumImage]];
        } else {
            ORKScaleRangeLabel *rightRangeLabel = [[ORKScaleRangeLabel alloc] initWithFrame:CGRectZero];
            rightRangeLabel.textAlignment = NSTextAlignmentCenter;
            rightRangeLabel.text = [formatProvider localizedStringForNumber:[formatProvider maximumNumber]];
            _rightRangeView = rightRangeLabel;
        }
        
        [self addSubview:_leftRangeView];
        [self addSubview:_rightRangeView];
        
        if ([formatProvider isVertical]) {
            _leftRangeDescriptionLabel.textAlignment = NSTextAlignmentLeft;
            _rightRangeDescriptionLabel.textAlignment = NSTextAlignmentLeft;
        } else {
            _leftRangeDescriptionLabel.textAlignment = NSTextAlignmentLeft;
            _rightRangeDescriptionLabel.textAlignment = NSTextAlignmentRight;
        }

        _leftRangeDescriptionLabel.text = [formatProvider minimumValueDescription];
        _rightRangeDescriptionLabel.text = [formatProvider maximumValueDescription];
        
        _slider.vertical = [formatProvider isVertical];
        
        _slider.maximumValue = [formatProvider maximumNumber].floatValue;
        _slider.minimumValue = [formatProvider minimumNumber].floatValue;
        
        NSInteger numberOfSteps = [formatProvider numberOfSteps];
        _slider.numberOfSteps = numberOfSteps;
        
        if (self.slider.textChoices) {
            _leftRangeDescriptionLabel.textColor = [UIColor blackColor];
            _rightRangeDescriptionLabel.textColor = [UIColor blackColor];
            _leftRangeLabel.text = @"";
            _rightRangeLabel.text = @"";
        }

        [_slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    
        self.translatesAutoresizingMaskIntoConstraints = NO;
        _leftRangeView.translatesAutoresizingMaskIntoConstraints = NO;
        _rightRangeView.translatesAutoresizingMaskIntoConstraints = NO;
        _slider.translatesAutoresizingMaskIntoConstraints = NO;
        _leftRangeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _rightRangeLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _leftRangeDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _rightRangeDescriptionLabel.translatesAutoresizingMaskIntoConstraints = NO;
        
        [self setUpConstraints];
    }
    return self;
}

- (void)setUpConstraints {
    NSDictionary *views = NSDictionaryOfVariableBindings(_slider, _leftRangeView, _rightRangeView, _valueLabel,_leftRangeDescriptionLabel, _rightRangeDescriptionLabel);
    
    NSMutableArray *constraints = [NSMutableArray new];
    if ([_formatProvider isVertical]) {
        _leftRangeDescriptionLabel.textAlignment = NSTextAlignmentLeft;
        _rightRangeDescriptionLabel.textAlignment = NSTextAlignmentLeft;
        
        // Vertical slider constraints
        // Keep the thumb the same distance from the value label as in horizontal mode
        const CGFloat kValueLabelSliderMargin = 23.0;
        // Keep the shadow of the thumb inside the bounds
        const CGFloat kSliderMargin = 20.0;
        const CGFloat kSideLabelMargin = 24;
        
        if (self.slider.textChoices) {
            // Remove the extra controls from superview.
            [_valueLabel removeFromSuperview];
            [_leftRangeView removeFromSuperview];
            [_rightRangeView removeFromSuperview];
            [_leftRangeDescriptionLabel removeFromSuperview];
            [_rightRangeDescriptionLabel removeFromSuperview];
            
            // Generating an array of labels for all the text choices.
            NSMutableArray *textChoiceLabels = [NSMutableArray new];
            for (int i = 0; i <= self.slider.numberOfSteps; i++) {
                ORKTextChoice *textChoice = self.slider.textChoices[i];
                ORKScaleRangeLabel *stepLabel = [[ORKScaleRangeLabel alloc] initWithFrame:CGRectZero];
                stepLabel.text = textChoice.text;
                stepLabel.textAlignment = NSTextAlignmentLeft;
                stepLabel.translatesAutoresizingMaskIntoConstraints = NO;
                [self addSubview:stepLabel];
                [textChoiceLabels addObject:stepLabel];
            }
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:_slider
                                                             attribute:NSLayoutAttributeCenterY
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:self
                                                             attribute:NSLayoutAttributeCenterY
                                                            multiplier:1.0
                                                              constant:0]];
            
            [self addConstraints:
             [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-kSliderMargin-[_slider]-kSliderMargin-|"
                                                     options:NSLayoutFormatDirectionLeadingToTrailing
                                                     metrics:@{@"kSliderMargin": @(kSliderMargin)}
                                                       views:views]];
            
            
            for (int i = 0; i < textChoiceLabels.count; i++) {
                
                // Move to the right side of the slider.
                [self addConstraint:[NSLayoutConstraint constraintWithItem:textChoiceLabels[i]
                                                                 attribute:NSLayoutAttributeLeading
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.slider
                                                                 attribute:NSLayoutAttributeCenterX
                                                                multiplier:1.0
                                                                  constant:kSideLabelMargin]];
                
                if (i == 0) {
                    
                    /*
                     First label constraints
                     */
                    [self addConstraints:@[
                                           [NSLayoutConstraint constraintWithItem:textChoiceLabels[i]
                                                                        attribute:NSLayoutAttributeCenterX
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeCenterX
                                                                       multiplier:1.0
                                                                         constant:0],
                                           [NSLayoutConstraint constraintWithItem:textChoiceLabels[i]
                                                                        attribute:NSLayoutAttributeCenterY
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:self.slider
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0
                                                                         constant:0],
                                           [NSLayoutConstraint constraintWithItem:textChoiceLabels[i]
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationLessThanOrEqual
                                                                           toItem:self
                                                                        attribute:NSLayoutAttributeWidth
                                                                       multiplier:0.5
                                                                         constant:0]
                                           ]];
                } else {
                    
                    /*
                     In-between labels constraints
                     */
                    
                    [self addConstraints:@[
                                           [NSLayoutConstraint constraintWithItem:textChoiceLabels[i-1]
                                                                        attribute:NSLayoutAttributeTop
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:textChoiceLabels[i]
                                                                        attribute:NSLayoutAttributeBottom
                                                                       multiplier:1.0
                                                                         constant:0],
                                           [NSLayoutConstraint constraintWithItem:textChoiceLabels[i-1]
                                                                        attribute:NSLayoutAttributeHeight
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:textChoiceLabels[i]
                                                                        attribute:NSLayoutAttributeHeight
                                                                       multiplier:1.0
                                                                         constant:0],
                                           [NSLayoutConstraint constraintWithItem:textChoiceLabels[i-1]
                                                                        attribute:NSLayoutAttributeWidth
                                                                        relatedBy:NSLayoutRelationEqual
                                                                           toItem:textChoiceLabels[i]
                                                                        attribute:NSLayoutAttributeWidth
                                                                       multiplier:1.0
                                                                         constant:0]
                                           ]];
                    
                    /*
                     Last label constraints
                     */
                    if (i==textChoiceLabels.count-1) {
                        [self addConstraint:[NSLayoutConstraint constraintWithItem:textChoiceLabels[i]
                                                                         attribute:NSLayoutAttributeCenterY
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:self.slider
                                                                         attribute:NSLayoutAttributeTop
                                                                        multiplier:1.0
                                                                          constant:0]];
                    }
                }
            }
        } else {
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_slider
                                                                attribute:NSLayoutAttributeCenterX
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:self
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0
                                                                 constant:0.0]];
            
            [constraints addObjectsFromArray:
             [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_valueLabel]-(>=kValueLabelSliderMargin)-[_slider]-(>=kSliderMargin)-|"
                                                     options:NSLayoutFormatAlignAllCenterX | NSLayoutFormatDirectionLeadingToTrailing
                                                     metrics:@{@"kValueLabelSliderMargin": @(kValueLabelSliderMargin), @"kSliderMargin": @(kSliderMargin)}
                                                       views:views]];
            
            [constraints addObjectsFromArray:
             [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_valueLabel]-(>=8)-[_rightRangeDescriptionLabel]"
                                                     options:NSLayoutFormatDirectionLeadingToTrailing
                                                     metrics:nil
                                                       views:views]];
            
            [constraints addObjectsFromArray
             :[NSLayoutConstraint constraintsWithVisualFormat:@"H:[_rightRangeView(==_leftRangeView)]"
                                                      options:(NSLayoutFormatOptions)0
                                                      metrics:nil
                                                        views:views]];
            
            // Set the margin between slider and the rangeViews
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_rightRangeView
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_slider
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0
                                                                 constant:-kSideLabelMargin]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_leftRangeView
                                                                attribute:NSLayoutAttributeRight
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_slider
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0
                                                                 constant:-kSideLabelMargin]];
            
            // Align the rangeViews with the slider's bottom
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_rightRangeView
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_slider
                                                                attribute:NSLayoutAttributeTop
                                                               multiplier:1.0
                                                                 constant:0.0]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_leftRangeView
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_slider
                                                                attribute:NSLayoutAttributeBottom
                                                               multiplier:1.0
                                                                 constant:0.0]];
            
            [constraints addObjectsFromArray:
             [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_rightRangeDescriptionLabel]-(>=8)-|"
                                                     options:NSLayoutFormatDirectionLeadingToTrailing
                                                     metrics:nil
                                                       views:views]];
            [constraints addObjectsFromArray:
             [NSLayoutConstraint constraintsWithVisualFormat:@"H:[_leftRangeDescriptionLabel(==_rightRangeDescriptionLabel)]-(>=8)-|"
                                                     options:NSLayoutFormatDirectionLeadingToTrailing
                                                     metrics:nil
                                                       views:views]];
            
            [constraints addObjectsFromArray:
             [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_rightRangeDescriptionLabel]-(>=8)-[_leftRangeDescriptionLabel]-(>=8)-|"
                                                     options:NSLayoutFormatDirectionLeadingToTrailing
                                                     metrics:nil
                                                       views:views]];
            
            // Set the margin between the slider and the descriptionLabels
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_rightRangeDescriptionLabel
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_slider
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0
                                                                 constant:kSideLabelMargin]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_leftRangeDescriptionLabel
                                                                attribute:NSLayoutAttributeLeft
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_slider
                                                                attribute:NSLayoutAttributeCenterX
                                                               multiplier:1.0
                                                                 constant:kSideLabelMargin]];
            
            // Limit the height of the descriptionLabels
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.rightRangeDescriptionLabel
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationLessThanOrEqual
                                                                toItem:_slider
                                                             attribute:NSLayoutAttributeHeight
                                                            multiplier:0.5
                                                              constant:kSliderMargin]];
            
            [self addConstraint:[NSLayoutConstraint constraintWithItem:self.leftRangeDescriptionLabel
                                                             attribute:NSLayoutAttributeHeight
                                                             relatedBy:NSLayoutRelationLessThanOrEqual
                                                                toItem:_slider
                                                             attribute:NSLayoutAttributeHeight
                                                            multiplier:0.5
                                                              constant:kSliderMargin]];
            
            
            // Align the descriptionLabels with the rangeViews
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_rightRangeDescriptionLabel
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_rightRangeView
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1.0
                                                                 constant:0.0]];
            
            [constraints addObject:[NSLayoutConstraint constraintWithItem:_leftRangeDescriptionLabel
                                                                attribute:NSLayoutAttributeCenterY
                                                                relatedBy:NSLayoutRelationEqual
                                                                   toItem:_leftRangeView
                                                                attribute:NSLayoutAttributeCenterY
                                                               multiplier:1.0
                                                                 constant:0.0]];
        }
    } else {
        // Horizontal slider constraints
        [constraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_valueLabel]-[_slider]-(>=8)-|"
                                                 options:NSLayoutFormatAlignAllCenterX | NSLayoutFormatDirectionLeftToRight
                                                 metrics:nil
                                                   views:views]];
        [constraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_slider]-[_leftRangeDescriptionLabel]-(>=8)-|"
                                                 options:NSLayoutFormatDirectionLeftToRight
                                                 metrics:nil
                                                   views:views]];
        [constraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"V:[_slider]-[_rightRangeDescriptionLabel]-(>=8)-|"
                                                 options:NSLayoutFormatDirectionLeftToRight
                                                 metrics:nil
                                                   views:views]];
        
        const CGFloat kMargin = 17.0;
        [constraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-kMargin-[_leftRangeView]-kMargin-[_slider]-kMargin-[_rightRangeView(==_leftRangeView)]-kMargin-|"
                                                 options:NSLayoutFormatAlignAllCenterY | NSLayoutFormatDirectionLeftToRight
                                                 metrics:@{@"kMargin": @(kMargin)}
                                                   views:views]];
        [constraints addObjectsFromArray:
         [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-kMargin-[_leftRangeDescriptionLabel]-(>=16)-[_rightRangeDescriptionLabel(==_leftRangeDescriptionLabel)]-kMargin-|"
                                                 options:NSLayoutFormatAlignAllCenterY | NSLayoutFormatDirectionLeftToRight
                                                 metrics:@{@"kMargin": @(kMargin)}
                                                   views:views]];
    }
    [NSLayoutConstraint activateConstraints:constraints];
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        _slider = [[ORKScaleSlider alloc] initWithFrame:CGRectZero];
        _slider.userInteractionEnabled = YES;
        _slider.contentMode = UIViewContentModeRedraw;
        [self addSubview:_slider];
        
        _leftRangeLabel = [[ORKScaleRangeLabel alloc] initWithFrame:CGRectZero];
        _leftRangeLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_leftRangeLabel];
        
        _leftRangeDescriptionLabel = [[ORKScaleRangeDescriptionLabel alloc] initWithFrame:CGRectZero];        _leftRangeDescriptionLabel.numberOfLines = -1;
        [self addSubview:_leftRangeDescriptionLabel];
        
        _rightRangeLabel = [[ORKScaleRangeLabel alloc] initWithFrame:CGRectZero];
        _rightRangeLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:_rightRangeLabel];
        
        _rightRangeDescriptionLabel = [[ORKScaleRangeDescriptionLabel alloc] initWithFrame:CGRectZero];        _rightRangeDescriptionLabel.numberOfLines = -1;
        [self addSubview:_rightRangeDescriptionLabel];

             
        _valueLabel = [[ORKScaleValueLabel alloc] initWithFrame:CGRectZero];
        _valueLabel.textAlignment = NSTextAlignmentCenter;
        _valueLabel.text = @" ";
        [self addSubview:_valueLabel];
        
#if LAYOUT_DEBUG
        self.backgroundColor = [UIColor greenColor];
        _valueLabel.backgroundColor = [UIColor blueColor];
        _slider.backgroundColor = [UIColor redColor];
        _leftRangeDescriptionLabel.backgroundColor = [UIColor yellowColor];
        _rightRangeDescriptionLabel.backgroundColor = [UIColor yellowColor];
#endif
    }
    return self;
}

- (void)setCurrentValue:(NSNumber *)value {
    _currentValue = value;
    _slider.showThumb = value? YES : NO;
    
    NSArray *textChoices = [_formatProvider textChoices];
    if (textChoices && value) {
        ORKTextChoice *textChoice = textChoices[MAX(0, [value intValue] - 1)];
        self.valueLabel.text = textChoice.text;
    } else if (value) {
        NSNumber *newValue = [_formatProvider normalizedValueForNumber:value];
        _slider.value = newValue.floatValue;
        _valueLabel.text = [_formatProvider localizedStringForNumber:newValue];
    } else {
        _valueLabel.text = @"";
    }
}

- (IBAction)sliderValueChanged:(id)sender {
    NSNumber *newValue = [_formatProvider normalizedValueForNumber:@(_slider.value)];
    [self setCurrentValue:newValue];
}

#pragma mark - Accessibility

// Since the slider is the only interesting thing within this cell, we make the
// cell a container with only one element, i.e. the slider.

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSInteger)accessibilityElementCount {
    return (_slider != nil ? 1 : 0);
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    return _slider;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    return (element == _slider ? 0 : NSNotFound);
}

@end
