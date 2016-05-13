#import "GGLContext.h"

#import <GINInvite/GINInvite.h>
#import <GINInvite/GINInviteTargetApplication.h>

/**
 * This category extends |GGLContext| with the Google App Invite service. Import
 * GGLContext+AppInvite to use Google App Invite in your app.
 *
 * [GIDSignIn sharedInstance], |[GGLContext sharedInstance].inviteDialog| and
 * |[GGLContext sharedInstance].targetApp| should be ready to use after calling
 * -[[GGLContext sharedInstance] configureWithError:].
 *
 * @see GGLContext
 */
@interface GGLContext (AppInvite)

/**
 * App Invite requires defining the client ID if the invite is received on a different
 * platform than iOS. If an Android client ID is defined in the GoogleService-Info.plist
 * it will automatically be configured as a target app for new invites. This property
 * allows retreving a copy of that |GINInviteTargetApplication|.
 */
@property(nonatomic, readonly, strong) GINInviteTargetApplication *targetApp;

@end
