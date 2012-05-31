#import <UIKit/UIKit.h>

/**
 A NDRotator object is a visual control used to select one or two values from a continuous range of values. Rotator are always displayed as circular dials. An indicator, or thumb, notes the current value of the rotator and can be moved by the user to change the setting with a turning action and the choice of radius action as well for a second value.

 ### Subclassing Notes
 The NDRotator class is designed to be subclassed to change the appearance. NDRotator performs caching of it elements to allow for smooth animation on low power devices like the iPhone, the methods to override work with this caching so you do not have to reimplement this yourself.

 #### Methods to Override

 When subclassing NDRotator, there are only a handful of methods you need to override. NDRotator is designed to do as much as possible to implement you own rotator style control, it is based around a control made up of two parts which do not change appearance for changing values but instead the position of a thumb element changes with respect to the body of the control.
 if you need to, you can override any of the following methods in your NDRotator subclasses:

 - Initialization:
 initWithFrame:, initWithCoder: -Just like subclassing and <UIView> you may want to override the initialisation methods initWithFrame: and initWithCoder: to add the initialisation of you own properties.
 - Coding:
 initWithCoder:, encodeWithCoder: -If you want to add your own values to be encoded and decoded you will then have to override these two methods you should call the super implementation.
 - Drawing:
 drawBodyInRect:hilighted:, drawThumbInRect:hilighted: -you will need to override these two methods to change the appearance of Rotator's, unless you want to just modify the default look, for example you could just override drawThumbInRect:hilighted: if you just want to change the thumb but keep the same body, you do no want to call the super implementations in your implementations.
 bodyRect, thumbRect -If you override <drawBodyInRect:hilighted:> <drawThumbInRect:hilighted:>, you will need to override the corresponding rect property to give NDRotator information on how to calculating the thumb position.
 - Behaviour:
 setStyle: -This method is can be overriden if want to limit which styles are supported, for example, the <NDRotatorStyleDisc> style offten will not be appropriate, if you are the only user of your subclass, then this is not nessecary as you can choose to just not use it this way.

 */
@interface NDRotator : UIControl <NSCoding>

/**
 Contains the angle of the receiver in radians.

 This value will be constrained by the values (<minimumDomain>,<maximumDomain>) and so can represent a range of values greater than one turn.
 */
@property(nonatomic) CGFloat angle;

/**
 Contains the thumb point where (0.0,0.0) is the center, (1.0,0.0) is at 3 oclock and (0.0,-1.0) is at 12 oclock etc.

 The point can go beyound the bounds (-1.0,-1.0) and (1.0,1.0) for <radius> values greated the 1.0.
 */
@property(nonatomic) CGPoint cartesianPoint;

/**
 Contains the thumb point where (0.0,0.0) is the center, (1.0,0.0) is at 3 oclock and (0.0,-1.0) is at 12 oclock etc. The value is generated from a <radius> constrained to (0.0,1.0).

 This value is similar to <cartesianPoint> give a <radius> constrained to (0.0,1.0).
 */
@property(nonatomic, readonly)	CGPoint	constrainedCartesianPoint;

/**
 @name Accessing the Rotator’s Value Limits
 */

/**
 Contains the minimum value of the receiver.
 If you change the value of this property, and the current <value> of the receiver is below the new minimum, the current <value> is adjusted to match the new minimum value automatically.

 The default value of this property is 0.0.
 */
@property(nonatomic) CGFloat minimumValue;

/**
 Contains the maximum value of the receiver.
 If you change the value of this property, and the current <value> of the receiver is above the new maximum, the current <value> is adjusted to match the new maximum value automatically.

 The default value of this property is 1.0.
 */
@property(nonatomic) CGFloat maximumValue;

/**
 Contains the minimum <angle> of the receiver.
 The default value of this property is 0.0.
 */
@property(nonatomic) CGFloat minimumDomain;

/**
 Contains the maximum <angle> of the receiver.
 The default value of this property is 2.0pi.
 */
@property(nonatomic) CGFloat maximumDomain;

/**
 @name Changing the Rotator’s Appearance
 */
/**
 @name Methods to call when subclassing
 */

/**
 Delete the thumb cache causing it to be recalculated
 This method is for subclass to call if the thumb images changes and needs to be redrawn
 */
- (void)deleteThumbCache;

/**
 Delete the disc cache causing it to be recalculated
 This method is for subclass to call if the disc images changes and needs to be redrawn
 */
- (void)deleteBodyCache;

/**
 @name Methods and properties to override when subclassing
 */

/**
 The rect used for the controls body.
 This rect may be smaller than the bounds of the control to allow for shadow effects. This rect is used to workout where the thumb position, the center of the rect is the point which the thumb rotates around.
 */
@property(nonatomic, readonly) CGRect bodyRect;

/**
 The rect used to contain the thumb image.
 This point (0.0,0.0) in the rect used to position the thumb, for a symetrical thumb the point (0.0,0.0) is the center of the rect.
 */
@property(nonatomic, readonly) CGRect thumbRect;

/**
 draw the control body into the given <rect>.
 The <rect> supplied is the size of the reciever <bounds> of the control not the rect returned from the property <bodyRect>. The drawing is cached and so is not called all the time, to force the body to be redrawed again call <deleteBodyCache>. This methods is called twice, <hilighted> set and unset, if there is no difference between the two versions then return NO for one of the versions this will result in one version being used for both hilighted and unhilighted.
 */
- (BOOL)drawBodyInRect:(CGRect)rect hilighted:(BOOL)hilighted;

/**
 draw the control thumb into the given rect.
 The <rect> supplied is the size of the rect returned from <thumbRect>, but the origin is not. The drawing is cahced and so is not called all the time, to force the thumb to be redrawed again call <deleteThumbCache>. This methods is called twice, <hilighted> set and unset, if there is no difference between the two versions then return NO for one of the versions this will result in one version being used for both hilighted and unhilighted.
 */
- (BOOL)drawThumbInRect:(CGRect)rect hilighted:(BOOL)hilighted;

@end
