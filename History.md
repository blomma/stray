
n.n.n / 2014-12-08
==================

  * Updated pods
  * Work unresolved
  * Updated pods
  * Updated crashlytics
  * Updated Crashlytics
  * Removed extra whitespace
  * Swiftified code
  * When you change tag in events the new name isn’t shown until you refresh the view, fixes #11
  * Very long tag names go beyond the border in tags and events view, fixes #10
  * Selection in Events and Tags are shown after views is ready, fixes #9
  * Helvetica Neueu and new layout
  * Red is the best color for trashcan
  * Use Helvetica Neue instead
  * start and end date next to each other
  * Fixed selection
  * Fixed selection
  * Added EndDate
  * Converted RootViewController to swift and a UIView
  * Initial statistics view
  * Replaced LaunchImages with LaunchScreen
  * Upped the font size to 18
  * Leftover reference to TagTableViewCellBackView
  * Added MR_ENABLE_ACTIVE_RECORD_LOGGING=0
  * Check if we are doing interactive before actually doing it
  * Fix for not receiving a Ended message from the gesture
  * Register gesture to window
  * Dimming view while transition
  * Slide up interactive
  * Removed use of TagButton
  * Updated mogenerator arguments
  * Removed unused frameworks
  * Removed use of NoHitCAShapeLayer, not really needed
  * Revert "Make clock face visible in storyboard"
  * Removed dead import
  * Renamed constraint prop for clarity
  * Removed undeeded init
  * Make clock face visible in storyboard
  * Converted to swift
  * Moved Views to Views folder
  * Removed old unused version system
  * Turned on some warnings
  * Converted to swift
  * Also reset trailing constant
  * Don't close edit state when scrolling
  * nil self.selectedEvent
  * Cache selectedEvent
  * Set InEditState before animation is finished
  * dispatch on main ui thread
  * Removed delegate use in Tags controller
  * nil out fetchedresultcontroller and delegate
  * Standardize on     __weak __typeof__(self) _self = self;
  * Make sure to reset selectedEventGUID
  * Reworked events view to modern standards
  * Removed pref and infohint from storyboard
  * Move frontView on cell instead of sqiching it together, fixes label
  * Long push on tag edit triggers reorder, fixes #5
  * Fixed conversion warnings
  * Can now move startdate to after now
  * Removed other_ldflags from build Updated cocoapods
  * Updated launchimage
  * isStopped needs to be calculated right
  * Tweaked layout of timer screen
  * Removed inhibit_all_warnings on pods to be able to run analyzer
  * Updated to ios 8 in podfile
  * Removed Dropbox integration and Information view
  * Moved to NSFetchResultController
  * Calculate the correct build number
  * Xcode wanted to change the version number
  * Updated AppIcons and LaunchImages, moved them over to ImageAssets
  * Future reminder
  * Reset frontView leading constant on cell reuse
  * Enable swipe on TagsTableViewController
  * TagsTableViewController now takes a eventGUID instead of the event
  * Close after tag is selected
  * Removed selectedEvent from State and add selectedEventGUID instead
  * Fixed  problem with updating now/stopDate
  * Removed SDCloudUserDefaults
  * Removed SKBounceAnimation
  * Removed unused segues
  * Rewrote moving a cell in swift and broke it out in separate class
  * Updated Crashlytics or more correct Crashlytics updated itself
  * Removed dead folder
  * Removed dead code
  * Rebuilt mogenerator files
  * Removed moot points
  * Anchored timer to top layout instead to avoid awkward finger placement
  * Recoded how the timer layout is handled
  * Removed FontAwesomeKit, instead use imported Font Awesome
  * Fixed label position and removed use of FontAwesomeKit
  * Removed unused code
  * Fixed misplaced frame
  * Fixed warnings
  * Removed PopoverView since it was no longer used
  * Removed Api since we longer poke our own server
  * Convert TagsTableViewController to autolayout
  * Immediate return from autoscroll if not needed Trigger a needsMoveAtIndexPath when autoscrolling use fabs instead of fabsf for conversion
  * Increment build version based on number of commits on branch, does not change the Info.plist in project but instead modifies the built application
  * Updated Crashlytics
  * New provisioning profile and deploy target is now ios 8
  * Cleaned up cocoapods, Updated Dropbox, Updated Crashlytics
  * Updated Crashlytics
  * Added font awesome as a font
  * Made good use of autolayout
  * Commented out google analytics
