# Animations, Transformations, and Design System

## Animations

### Page Transitions
The app uses custom page transitions defined in `lib/utils/page_transitions.dart`:
- **Slide Up**: Used for modals or new screens (e.g., creating a new entry).
  - `PageTransitions.slideUp(Widget page)`
  - Animates from `Offset(0.0, 1.0)` to `Offset.zero` with `Curves.easeInOut`.
  - Duration: 300ms.
- **Fade**: Used for tab switching or subtle transitions.
  - `PageTransitions.fade(Widget page)`
  - Animates opacity from 0.0 to 1.0.
  - Duration: 200ms.
- **Slide Right**: Used for standard navigation.
  - `PageTransitions.slideRight(Widget page)`
  - Animates from `Offset(1.0, 0.0)` to `Offset.zero` with `Curves.easeInOut`.
  - Duration: 300ms.

### Component Animations
- **Lottie Animations**:
  - Used for the mascot in `ProfileScreen` (currently being replaced by Notion Avatar) and potentially other areas.
  - Implementation: `Lottie.asset('assets/mascot/idle.json')`.
- **Smooth Page Indicator**:
  - Used in `OnboardingScreen`.
  - Effect: `WormEffect` with `activeDotColor: RythamoColors.salmonOrange`.

## Transformations
- **Scale/Position**:
  - `Transform.translate` or `SlideTransition` are used within the page transitions.
  - `Transform.scale` is not explicitly used in the core widgets reviewed but is available for interactive elements if needed.

## Design System & Color Themes

### Color Palette (`RythamoColors`)
- **Salmon Orange**: `Color(0xFFFF6B6B)` - Primary accent color.
- **Mint Green**: `Color(0xFFB8E0C3)` - Secondary accent.
- **Dark Charcoal**: `Color(0xFF1C1C1E)` - Primary text color for light backgrounds.

### Themes (`RythamoTheme`)
The app uses a flavor-based theme system (Catppuccin) with 4 modes:
1.  **Latte** (Light Mode)
2.  **Frappé** (Soft Dark)
3.  **Macchiato** (Warm Dark)
4.  **Mocha** (Deep Dark)

**Theme Logic:**
- `RythamoTheme.getTheme(RythamoThemeMode mode)` returns a `ThemeData` object.
- It maps the `RythamoThemeMode` enum to `catppuccin` flavors.
- **Light Mode Check**: `mode == RythamoThemeMode.latte` determines if `Brightness.light` or `Brightness.dark` is used.

### Typography (`RythamoTypography`)
- **Header**: `GoogleFonts.inter`, small caps style (size 12, bold, letter spacing 1.5).
- **Metric Big**: `GoogleFonts.outfit`, large display text (size 48, bold).
- **Body**: `GoogleFonts.inter`, standard reading text (size 16).
- **Handwriting**: `GoogleFonts.indieFlower`, used for personal/journal feel.
- **Funny Header**: `GoogleFonts.amaticSc`, used for playful headers.

**Dynamic Styles**:
Helper methods like `headerDynamic(Color color)` allow adapting text color based on the active theme (e.g., white for dark modes, dark charcoal for light mode).
