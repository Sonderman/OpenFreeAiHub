import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

class AppTheme {
  // Default seed color
  static const Color defaultLightSeedColor = Colors.indigo;
  static const Color defaultDarkSeedColor = Colors.orange;

  // Light theme with color seeding (legacy support)
  static ThemeData lightTheme([Color? seedColor]) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor ?? defaultLightSeedColor,
        brightness: Brightness.light,
      ),
    );
  }

  /// Get light theme based on FlexScheme
  static ThemeData getFlexLightTheme(FlexScheme scheme) {
    return FlexThemeData.light(
      scheme: scheme,
      useMaterial3: true,
      // Add some default customizations
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 10,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        // Card theme customizations
        cardRadius: 16.0,
        // AppBar theme customizations
        appBarBackgroundSchemeColor: SchemeColor.primary,
        appBarForegroundSchemeColor: SchemeColor.onPrimary,
        // Elevated button customizations
        elevatedButtonRadius: 24.0,
        elevatedButtonSchemeColor: SchemeColor.primary,
        elevatedButtonSecondarySchemeColor: SchemeColor.onPrimary,
        // Filled button customizations
        filledButtonRadius: 24.0,
        // Outlined button customizations
        outlinedButtonRadius: 24.0,
        // Text button customizations
        textButtonRadius: 24.0,
        // Input decoration customizations
        inputDecoratorRadius: 16.0,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorBorderSchemeColor: SchemeColor.outline,
        inputDecoratorFocusedBorderWidth: 2.0,
        // Floating action button customizations
        fabRadius: 16.0,
        fabSchemeColor: SchemeColor.primary,
        // Chip customizations
        chipRadius: 16.0,
        chipSchemeColor: SchemeColor.primaryContainer,
        chipSelectedSchemeColor: SchemeColor.primary,
        // Dialog customizations
        dialogRadius: 20.0,
        // Navigation bar customizations
        navigationBarBackgroundSchemeColor: SchemeColor.surface,
        navigationBarSelectedIconSchemeColor: SchemeColor.primary,
        navigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
        navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
        navigationBarIndicatorRadius: 16.0,
        // Tab bar customizations
        tabBarIndicatorSchemeColor: SchemeColor.primary,
        tabBarItemSchemeColor: SchemeColor.onSurface,
        // Drawer customizations
        drawerBackgroundSchemeColor: SchemeColor.surface,
        // Bottom sheet customizations
        bottomSheetRadius: 20.0,
        bottomSheetBackgroundColor: SchemeColor.surface,
        // Menu customizations
        menuRadius: 12.0,
        // Popup menu customizations
        popupMenuRadius: 12.0,
        // Switch customizations
        switchSchemeColor: SchemeColor.primary,
        // Checkbox customizations
        checkboxSchemeColor: SchemeColor.primary,
        // Radio customizations
        radioSchemeColor: SchemeColor.primary,
        // Slider customizations
        sliderBaseSchemeColor: SchemeColor.primary,
        sliderIndicatorSchemeColor: SchemeColor.primary,
      ),
    );
  }

  /// Get dark theme based on FlexScheme
  static ThemeData getFlexDarkTheme(FlexScheme scheme) {
    return FlexThemeData.dark(
      scheme: scheme,
      useMaterial3: true,
      // Add some default customizations
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 20,
        blendOnColors: false,
        useMaterial3Typography: true,
        useM2StyleDividerInM3: true,
        // Card theme customizations
        cardRadius: 16.0,
        // AppBar theme customizations
        appBarBackgroundSchemeColor: SchemeColor.primary,
        appBarForegroundSchemeColor: SchemeColor.onPrimary,
        // Elevated button customizations
        elevatedButtonRadius: 24.0,
        elevatedButtonSchemeColor: SchemeColor.primary,
        elevatedButtonSecondarySchemeColor: SchemeColor.onPrimary,
        // Filled button customizations
        filledButtonRadius: 24.0,
        // Outlined button customizations
        outlinedButtonRadius: 24.0,
        // Text button customizations
        textButtonRadius: 24.0,
        // Input decoration customizations
        inputDecoratorRadius: 16.0,
        inputDecoratorSchemeColor: SchemeColor.primary,
        inputDecoratorBorderSchemeColor: SchemeColor.outline,
        inputDecoratorFocusedBorderWidth: 2.0,
        // Floating action button customizations
        fabRadius: 16.0,
        fabSchemeColor: SchemeColor.primary,
        // Chip customizations
        chipRadius: 16.0,
        chipSchemeColor: SchemeColor.primaryContainer,
        chipSelectedSchemeColor: SchemeColor.primary,
        // Dialog customizations
        dialogRadius: 20.0,
        // Navigation bar customizations
        navigationBarBackgroundSchemeColor: SchemeColor.surface,
        navigationBarSelectedIconSchemeColor: SchemeColor.primary,
        navigationBarUnselectedIconSchemeColor: SchemeColor.onSurface,
        navigationBarIndicatorSchemeColor: SchemeColor.primaryContainer,
        navigationBarIndicatorRadius: 16.0,
        // Tab bar customizations
        tabBarIndicatorSchemeColor: SchemeColor.primary,
        tabBarItemSchemeColor: SchemeColor.onSurface,
        // Drawer customizations
        drawerBackgroundSchemeColor: SchemeColor.surface,
        // Bottom sheet customizations
        bottomSheetRadius: 20.0,
        bottomSheetBackgroundColor: SchemeColor.surface,
        // Menu customizations
        menuRadius: 12.0,
        // Popup menu customizations
        popupMenuRadius: 12.0,
        // Switch customizations
        switchSchemeColor: SchemeColor.primary,
        // Checkbox customizations
        checkboxSchemeColor: SchemeColor.primary,
        // Radio customizations
        radioSchemeColor: SchemeColor.primary,
        // Slider customizations
        sliderBaseSchemeColor: SchemeColor.primary,
        sliderIndicatorSchemeColor: SchemeColor.primary,
      ),
    );
  }

  /// Get theme based on user preferences
  static ThemeData getThemeFromPreferences({
    required FlexScheme colorScheme,
    required bool isDark,
  }) {
    return isDark ? getFlexDarkTheme(colorScheme) : getFlexLightTheme(colorScheme);
  }

  /// Get all available color schemes with their display names
  static Map<FlexScheme, String> getAvailableColorSchemes() {
    return {
      // Material 3 Schemes
      FlexScheme.materialBaseline: 'Material Baseline',
      FlexScheme.redM3: 'Thunderbird Red',
      FlexScheme.pinkM3: 'Lipstick Pink',
      FlexScheme.purpleM3: 'Eggplant Purple',
      FlexScheme.indigoM3: 'Indigo San Marino',
      FlexScheme.blueM3: 'Endeavour Blue',
      FlexScheme.cyanM3: 'Mosque Cyan',
      FlexScheme.tealM3: 'Blue Stone Teal',
      FlexScheme.greenM3: 'Camarone Green',
      FlexScheme.limeM3: 'Verdun Lime',
      FlexScheme.yellowM3: 'Yukon Gold Yellow',
      FlexScheme.orangeM3: 'Brown Orange',
      FlexScheme.deepOrangeM3: 'Rust Deep Orange',

      // Classic Schemes
      FlexScheme.material: 'Material Default',
      FlexScheme.blue: 'Blue Delight',
      FlexScheme.indigo: 'Indigo Nights',
      FlexScheme.hippieBlue: 'Hippie Blue',
      FlexScheme.aquaBlue: 'Aqua Blue',
      FlexScheme.brandBlue: 'Brand Blues',
      FlexScheme.deepBlue: 'Deep Blue Sea',
      FlexScheme.sakura: 'Pink Sakura',
      FlexScheme.mandyRed: 'Oh Mandy Red',
      FlexScheme.red: 'Red Tornado',
      FlexScheme.redWine: 'Red Red Wine',
      FlexScheme.purpleBrown: 'Purple Brown',
      FlexScheme.green: 'Green Forest',
      FlexScheme.money: 'Green Money',
      FlexScheme.jungle: 'Green Jungle',
      FlexScheme.greyLaw: 'Grey Law',
      FlexScheme.wasabi: 'Willow and Wasabi',
      FlexScheme.gold: 'Gold Sunset',
      FlexScheme.mango: 'Mango Mojito',
      FlexScheme.amber: 'Amber Blue',
      FlexScheme.vesuviusBurn: 'Vesuvius Burned',
      FlexScheme.deepPurple: 'Deep Purple',
      FlexScheme.ebonyClay: 'Ebony Clay',
      FlexScheme.barossa: 'Barossa',
      FlexScheme.shark: 'Shark and Orange',
      FlexScheme.bigStone: 'Big Stone Tulip',
      FlexScheme.damask: 'Damask and Lunar',
      FlexScheme.bahamaBlue: 'Bahama and Trinidad',
      FlexScheme.mallardGreen: 'Mallard and Valencia',
      FlexScheme.espresso: 'Espresso and Crema',
      FlexScheme.outerSpace: 'Outer Space Stage',
      FlexScheme.blueWhale: 'Blue Whale',
      FlexScheme.sanJuanBlue: 'San Juan Blue',
      FlexScheme.rosewood: 'Rosewood',
      FlexScheme.blumineBlue: 'Blumine',
      FlexScheme.flutterDash: 'Flutter Dash',
      FlexScheme.verdunHemlock: 'Verdun Green',
      FlexScheme.dellGenoa: 'Dell Genoa Green',

      // Neutral Schemes
      FlexScheme.blackWhite: 'Black & White',
      FlexScheme.greys: 'Monochrome Greys',
      FlexScheme.sepia: 'Sepia',

      // Shadcn Inspired Schemes
      FlexScheme.shadBlue: 'Shadcn Blue',
      FlexScheme.shadGray: 'Shadcn Gray',
      FlexScheme.shadGreen: 'Shadcn Green',
      FlexScheme.shadNeutral: 'Shadcn Neutral',
      FlexScheme.shadOrange: 'Shadcn Orange',
      FlexScheme.shadRed: 'Shadcn Red',
      FlexScheme.shadRose: 'Shadcn Rose',
      FlexScheme.shadSlate: 'Shadcn Slate',
      FlexScheme.shadStone: 'Shadcn Stone',
      FlexScheme.shadViolet: 'Shadcn Violet',
      FlexScheme.shadYellow: 'Shadcn Yellow',
      FlexScheme.shadZinc: 'Shadcn Zinc',
    };
  }

  /// Get display name for a specific color scheme
  static String getColorSchemeDisplayName(FlexScheme scheme) {
    return getAvailableColorSchemes()[scheme] ?? scheme.name;
  }
}
