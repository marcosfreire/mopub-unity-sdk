//
//  MoPubBinding.m
//  MoPubTest
//
//  Created by Mike DeSaro on 10/7/11.
//  Copyright (c) 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

#import "MoPubManager.h"
#import "MoPub.h"


// Converts C style string to NSString
#define GetStringParam( _x_ ) ( _x_ != NULL ) ? [NSString stringWithUTF8String:_x_] : [NSString stringWithUTF8String:""]

static double LAT_LONG_SENTINEL = 99999.0;


void _moPubEnableLocationSupport(bool shouldUseLocation )
{
    [[MoPubManager sharedManager]  enableLocationSupport:shouldUseLocation];
}


void _moPubCreateBanner( int bannerType, int bannerPosition, const char * adUnitId )
{
    MoPubBannerType type = (MoPubBannerType)bannerType;
    MoPubAdPosition position = (MoPubAdPosition)bannerPosition;

    [[MoPubManager managerForAdunit:GetStringParam( adUnitId )] createBanner:type atPosition:position];
}


void _moPubDestroyBanner(const char * adUnitId)
{
    [[MoPubManager managerForAdunit:GetStringParam( adUnitId )] destroyBanner];
}


void _moPubShowBanner( const char * adUnitId, bool shouldShow )
{
    if( shouldShow )
        [[MoPubManager managerForAdunit:GetStringParam( adUnitId )] showBanner];
    else
        [[MoPubManager managerForAdunit:GetStringParam( adUnitId )] hideBanner:NO];
}


void _moPubRefreshAd( const char * adUnitId, const char * keywords )
{
    NSString *keys = keywords != NULL ? GetStringParam( keywords ) : nil;
    [[MoPubManager managerForAdunit:GetStringParam( adUnitId )] refreshAd:keys];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Interstitials

void _moPubRequestInterstitialAd( const char * adUnitId, const char * keywords )
{
    [[MoPubManager managerForAdunit:GetStringParam( adUnitId )] requestInterstitialAd:GetStringParam( keywords )];
}


void _moPubShowInterstitialAd( const char * adUnitId )
{
    [[MoPubManager managerForAdunit:GetStringParam( adUnitId )] showInterstitialAd];
}


void _moPubReportApplicationOpen(const char * iTunesAppId )
{
    [[MoPubManager sharedManager] reportApplicationOpen:GetStringParam( iTunesAppId )];
}


///////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Rewarded Videos

void _moPubInitializeRewardedVideo()
{
    [[MoPub sharedInstance] initializeRewardedVideoWithGlobalMediationSettings:nil delegate:[MoPubManager sharedManager]];
}



// adVendor is required key
// AdColonyInstanceMediationSettings, (BOOL)showPrePopup, (BOOL)showPostPopup
// VungleInstanceMediationSettings, (string)userIdentifier

void _moPubRequestRewardedVideo( const char * adUnitId, const char * json, const char * keywords, double latitude, double longitude, const char * customerId)
{
    NSMutableArray* mediationSettings = nil;

    if( json != NULL )
    {
        NSString* jsonString = GetStringParam( json );
        NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSArray* array = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        mediationSettings = [NSMutableArray array];

        for( NSDictionary* dict in array )
        {
            NSString* adVendor = [dict objectForKey:@"adVendor"];
            NSObject* mediationSetting = [NSClassFromString( [adVendor stringByAppendingString:@"InstanceMediationSettings"] ) new];

            if( !mediationSetting )
                continue;

            if( [adVendor isEqualToString:@"AdColony"] )
            {
                if( [dict.allKeys containsObject:@"showPrePopup"] )
                    [mediationSetting setValue:[dict objectForKey:@"showPrePopup"] forKey:@"showPrePopup"];

                if( [dict.allKeys containsObject:@"showPostPopup"] )
                    [mediationSetting setValue:[dict objectForKey:@"showPostPopup"] forKey:@"showPostPopup"];
            }
            else if( [adVendor isEqualToString:@"Vungle"] )
            {
                if( [dict.allKeys containsObject:@"userIdentifier"] )
                    [mediationSetting setValue:[dict objectForKey:@"userIdentifier"] forKey:@"userIdentifier"];
            }
            else if( [adVendor isEqualToString:@"UnityAds"] )
            {
                if( [dict.allKeys containsObject:@"userIdentifier"] )
                    [mediationSetting setValue:[dict objectForKey:@"userIdentifier"] forKey:@"userIdentifier"];
            }

            [mediationSettings addObject:mediationSetting];
            NSLog( @"adding mediation settings %@ for mediation class [%@]", dict, [mediationSetting class] );
        }
    }

    CLLocation *location = nil;
    if (latitude != LAT_LONG_SENTINEL && longitude != LAT_LONG_SENTINEL) {
        location = [[CLLocation alloc] initWithLatitude:latitude longitude:longitude];
    }

    [MPRewardedVideo loadRewardedVideoAdWithAdUnitID:GetStringParam(adUnitId)
                                            keywords:GetStringParam(keywords)
                                            location:location
                                            customerId:GetStringParam(customerId)
                                   mediationSettings:mediationSettings];
}


void _moPubShowRewardedVideo( const char * adUnitId )
{
    NSString *adUnitString = GetStringParam( adUnitId );
    if( ![MPRewardedVideo hasAdAvailableForAdUnitID:adUnitString] )
    {
        NSLog( @"bailing out on showing rewarded video since it has not been loaded yet." );
        //return; // removed return here
    }

    [MPRewardedVideo presentRewardedVideoAdForAdUnitID:adUnitString fromViewController:[MoPubManager unityViewController]];
}
