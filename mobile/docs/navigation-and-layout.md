# Navigation and layout

## Menus per role

The main sections are branches of one `StatefulShellRoute`
(`lib/app/router/app_router.dart`), so each keeps its own history and scroll
position. `RoleNavigation` (`lib/app/shell/app_destinations.dart`) decides
which a user sees.

| Role | Bottom bar (phones) | On the More page |
| :--- | :--- | :--- |
| Collector | Home · Intake · Sales · Farmers · More | Customers |
| Admin | Home · Intake · Sales · Farmers · More | Customers, Reports, Staff |
| Board member | Home · Reports · Farmers · Buyers · More | Intake, Sales |

More also holds Settings, Change password and Log out.

- Bottom-bar labels are one word so they never wrap. "Customers" is shown as
  "Buyers" in the bar only, where a fifth of a small phone cannot fit it.
- From 600 dp wide (tablets, phones in landscape) the bar becomes a side rail
  listing every section; from 1200 dp it shows labels beside the icons. It
  scrolls when the screen is too short.
- Links to a section (for example a dashboard card) switch tabs with
  `context.go`; `context.push` would open a second copy on top.
- The router is created once and follows sign-in through
  `refreshListenable`, so tab history survives and the login screen stays up
  (with its spinner) while signing in.

## Screen sizes and text size

Rules the screens follow (`lib/core/layout/breakpoints.dart`):

- **Text in a row must be able to shrink.** Wrap names and labels in
  `Expanded`/`Flexible` with `maxLines` and `TextOverflow.ellipsis`, or use a
  `Wrap` for metadata lines so they continue on the next line.
- **Numbers shrink rather than wrap**: amounts sit in
  `FittedBox(fit: BoxFit.scaleDown)`.
- **No fixed aspect-ratio grids.** `ResponsiveGrid` fits as many cards per
  row as there is room for (two on phones, one with large text, up to four on
  tablets) and lets rows grow with the text.
- **Readable width on tablets**: forms and lists sit in `ReadableWidth`
  (720 dp for forms, 900 dp for lists) instead of stretching edge to edge.
- **Room for the floating button**: lists with one end with 88 dp of padding.
- **Text scaling** follows the phone's setting up to 1.3x (`main.dart`), and
  up to 1.1x in the bottom bar.

## Layout test

`test/layout/layout_test.dart` runs the real app with captured API responses
for each role and main screen, on these sizes, at 1.0x and the largest text:

| Name | Size (dp) |
| :--- | :--- |
| phone-small | 320 × 640 |
| phone | 360 × 800 |
| phone-large | 430 × 932 |
| phone-landscape | 800 × 360 |
| tablet | 800 × 1280 |
| tablet-landscape | 1280 × 800 |

It fails on any layout error and reports the widget's file and line, for
example `RenderFlex overflowed by 24 pixels [features/.../screen.dart:314]`.
It also checks key text, such as the set-price button for a Sacco with no
price. When adding a screen, add its route to `_routesByRole`.
