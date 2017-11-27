//
//  HybridNavigator.m
//  TheOneHybrid
//
//  Created by jilei on 2017/11/14.
//  Copyright © 2017年 jilei. All rights reserved.
//

#import "HybridNavigator.h"
#import "Hybrid-Swift.h"

@implementation HybridNavigator

+ (NSString *)pluginName {
    return @"navigator";
}

- (void)push:(NSString *)url params:(NSDictionary *)params {
    UIViewController *vc = [[Router shared] webViewControllerWithRouteUrl:url params:params];
    if (!vc) {
        return;
    }
    
    UINavigationController *nv = [self currentNavigationController];
    if (nv) {
        [nv pushViewController:vc animated:YES];
    } else {
        Hybrid_LogWarning(@"Current NavigationController not found!");
    }
}

- (void)present:(NSString *)url params:(NSDictionary *)params {
    UIViewController *vc = [[Router shared] webViewControllerWithRouteUrl:url params:params];
    if (!vc) {
        return;
    }
    
    UIViewController *currentVC = [self currentViewController];
    if (currentVC) {
        if (currentVC.navigationController) {
            [currentVC.navigationController presentViewController:vc animated:YES completion:nil];
        } else {
            [currentVC presentViewController:vc animated:YES completion:nil];
        }
        return;
    }
    Hybrid_LogWarning(@"Current ViewController not found");
}

- (void)pop {
    [[self currentNavigationController] popViewControllerAnimated:YES];
}

- (void)popToRoot {
    [[self currentNavigationController] popToRootViewControllerAnimated:YES];
}

#pragma mark - Private

- (UIViewController *)currentViewController {
    UIViewController *rootVC = [UIApplication sharedApplication].keyWindow.rootViewController;
    return [self findTopMostViewController:rootVC];
}

- (UINavigationController *)currentNavigationController {
    return [self currentViewController].navigationController;
}

- (UIViewController *)findTopMostViewController:(UIViewController *)vc {
    if (vc.presentedViewController) {
        return [self findTopMostViewController:vc.presentedViewController];
    } else if ([vc isKindOfClass:[UISplitViewController class]]) {
        UISplitViewController *svc = (UISplitViewController *)vc;
        if (svc.viewControllers.count > 0) {
            return [self findTopMostViewController:svc.viewControllers.lastObject];
        } else {
            return vc;
        }
    } else if ([vc isKindOfClass:[UINavigationController class]]) {
        // Return top view
        UINavigationController *svc = (UINavigationController *)vc;
        if (svc.viewControllers.count > 0) {
            return [self findTopMostViewController:svc.topViewController];
        } else {
            return vc;
        }
    } else if ([vc isKindOfClass:[UITabBarController class]]) {
        // Return visible view
        UITabBarController *svc = (UITabBarController *)vc;
        if (svc.viewControllers.count > 0) {
            return [self findTopMostViewController:svc.selectedViewController];
        } else {
            return vc;
        }
    } else {
        // Unknown view controller type, return last child view controller
        return vc;
    }
}

@end
