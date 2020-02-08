//
//  CoreDisplayPrivateAPI.h
//  Pock
//
//  Created by David Gstir on 08.02.20.
//  Copyright © 2020 David Gstir. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

CF_EXPORT void CoreDisplay_Display_SetUserBrightness(int CGDirectDisplayID, double level);
CF_EXPORT double CoreDisplay_Display_GetUserBrightness(int CGDirectDisplayID);

NS_ASSUME_NONNULL_END
