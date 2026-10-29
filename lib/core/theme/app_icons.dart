import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:path_parsing/path_parsing.dart';

/// A Lucide icon as the path data of its 24×24 SVG. Rendered by [AppIcon]
/// with a 2.75 stroke, which the fixed-weight Lucide icon fonts cannot do.
///
/// Generated from lucide-static 0.460.0 (ISC licence); circles, rects and
/// lines are converted to paths.
@immutable
class LucideIcon {
  const LucideIcon(this.name, this.paths);

  final String name;
  final List<String> paths;

  @override
  bool operator ==(Object other) => other is LucideIcon && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => 'LucideIcon($name)';
}

/// Every icon the app uses, from the one Lucide set.
abstract final class AppIcons {
  static const house = LucideIcon('house', ['M15 21v-8a1 1 0 0 0-1-1h-4a1 1 0 0 0-1 1v8', 'M3 10a2 2 0 0 1 .709-1.528l7-5.999a2 2 0 0 1 2.582 0l7 5.999A2 2 0 0 1 21 10v9a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z']);
  static const calendar = LucideIcon('calendar', ['M8 2v4', 'M16 2v4', 'M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2Z', 'M3 10h18']);
  static const dumbbell = LucideIcon('dumbbell', ['M14.4 14.4 9.6 9.6', 'M18.657 21.485a2 2 0 1 1-2.829-2.828l-1.767 1.768a2 2 0 1 1-2.829-2.829l6.364-6.364a2 2 0 1 1 2.829 2.829l-1.768 1.767a2 2 0 1 1 2.828 2.829z', 'm21.5 21.5-1.4-1.4', 'M3.9 3.9 2.5 2.5', 'M6.404 12.768a2 2 0 1 1-2.829-2.829l1.768-1.767a2 2 0 1 1-2.828-2.829l2.828-2.828a2 2 0 1 1 2.829 2.828l1.767-1.768a2 2 0 1 1 2.829 2.829z']);
  static const menu = LucideIcon('menu', ['M4 12L20 12', 'M4 6L20 6', 'M4 18L20 18']);
  static const qrCode = LucideIcon('qr-code', ['M4 3h3a1 1 0 0 1 1 1v3a1 1 0 0 1 -1 1h-3a1 1 0 0 1 -1 -1v-3a1 1 0 0 1 1 -1Z', 'M17 3h3a1 1 0 0 1 1 1v3a1 1 0 0 1 -1 1h-3a1 1 0 0 1 -1 -1v-3a1 1 0 0 1 1 -1Z', 'M4 16h3a1 1 0 0 1 1 1v3a1 1 0 0 1 -1 1h-3a1 1 0 0 1 -1 -1v-3a1 1 0 0 1 1 -1Z', 'M21 16h-3a2 2 0 0 0-2 2v3', 'M21 21v.01', 'M12 7v3a2 2 0 0 1-2 2H7', 'M3 12h.01', 'M12 3h.01', 'M12 16v.01', 'M16 12h1', 'M21 12v.01', 'M12 21v-1']);
  static const userCheck = LucideIcon('user-check', ['M16 21v-2a4 4 0 0 0-4-4H6a4 4 0 0 0-4 4v2', 'M5 7a4 4 0 1 0 8 0a4 4 0 1 0 -8 0Z', 'M16 11L18 13L22 9']);
  static const receipt = LucideIcon('receipt', ['M4 2v20l2-1 2 1 2-1 2 1 2-1 2 1 2-1 2 1V2l-2 1-2-1-2 1-2-1-2 1-2-1-2 1Z', 'M16 8h-6a2 2 0 1 0 0 4h4a2 2 0 1 1 0 4H8', 'M12 17.5v-11']);
  static const hourglass = LucideIcon('hourglass', ['M5 22h14', 'M5 2h14', 'M17 22v-4.172a2 2 0 0 0-.586-1.414L12 12l-4.414 4.414A2 2 0 0 0 7 17.828V22', 'M7 2v4.172a2 2 0 0 0 .586 1.414L12 12l4.414-4.414A2 2 0 0 0 17 6.172V2']);
  static const wallet = LucideIcon('wallet', ['M19 7V4a1 1 0 0 0-1-1H5a2 2 0 0 0 0 4h15a1 1 0 0 1 1 1v4h-3a2 2 0 0 0 0 4h3a1 1 0 0 0 1-1v-2a1 1 0 0 0-1-1', 'M3 5v14a2 2 0 0 0 2 2h15a1 1 0 0 0 1-1v-4']);
  static const smartphone = LucideIcon('smartphone', ['M7 2h10a2 2 0 0 1 2 2v16a2 2 0 0 1 -2 2h-10a2 2 0 0 1 -2 -2v-16a2 2 0 0 1 2 -2Z', 'M12 18h.01']);
  static const banknote = LucideIcon('banknote', ['M4 6h16a2 2 0 0 1 2 2v8a2 2 0 0 1 -2 2h-16a2 2 0 0 1 -2 -2v-8a2 2 0 0 1 2 -2Z', 'M10 12a2 2 0 1 0 4 0a2 2 0 1 0 -4 0Z', 'M6 12h.01M18 12h.01']);
  static const circleCheck = LucideIcon('circle-check', ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z', 'm9 12 2 2 4-4']);
  static const clock = LucideIcon('clock', ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z', 'M12 6L12 12L16 14']);
  static const circleAlert = LucideIcon('circle-alert', ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z', 'M12 8L12 12', 'M12 16L12.01 16']);
  static const cloudOff = LucideIcon('cloud-off', ['m2 2 20 20', 'M5.782 5.782A7 7 0 0 0 9 19h8.5a4.5 4.5 0 0 0 1.307-.193', 'M21.532 16.5A4.5 4.5 0 0 0 17.5 10h-1.79A7.008 7.008 0 0 0 10 5.07']);
  static const scanLine = LucideIcon('scan-line', ['M3 7V5a2 2 0 0 1 2-2h2', 'M17 3h2a2 2 0 0 1 2 2v2', 'M21 17v2a2 2 0 0 1-2 2h-2', 'M7 21H5a2 2 0 0 1-2-2v-2', 'M7 12h10']);
  static const sparkles = LucideIcon('sparkles', ['M9.937 15.5A2 2 0 0 0 8.5 14.063l-6.135-1.582a.5.5 0 0 1 0-.962L8.5 9.936A2 2 0 0 0 9.937 8.5l1.582-6.135a.5.5 0 0 1 .963 0L14.063 8.5A2 2 0 0 0 15.5 9.937l6.135 1.581a.5.5 0 0 1 0 .964L15.5 14.063a2 2 0 0 0-1.437 1.437l-1.582 6.135a.5.5 0 0 1-.963 0z', 'M20 3v4', 'M22 5h-4', 'M4 17v2', 'M5 18H3']);
  static const trendingUp = LucideIcon('trending-up', ['M22 7L13.5 15.5L8.5 10.5L2 17', 'M16 7L22 7L22 13']);
  static const history = LucideIcon('history', ['M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8', 'M3 3v5h5', 'M12 7v5l4 2']);
  static const trophy = LucideIcon('trophy', ['M6 9H4.5a2.5 2.5 0 0 1 0-5H6', 'M18 9h1.5a2.5 2.5 0 0 0 0-5H18', 'M4 22h16', 'M10 14.66V17c0 .55-.47.98-.97 1.21C7.85 18.75 7 20.24 7 22', 'M14 14.66V17c0 .55.47.98.97 1.21C16.15 18.75 17 20.24 17 22', 'M18 2H6v7a6 6 0 0 0 12 0V2Z']);
  static const bookOpen = LucideIcon('book-open', ['M12 7v14', 'M3 18a1 1 0 0 1-1-1V4a1 1 0 0 1 1-1h5a4 4 0 0 1 4 4 4 4 0 0 1 4-4h5a1 1 0 0 1 1 1v13a1 1 0 0 1-1 1h-6a3 3 0 0 0-3 3 3 3 0 0 0-3-3z']);
  static const circleUser = LucideIcon('circle-user', ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z', 'M9 10a3 3 0 1 0 6 0a3 3 0 1 0 -6 0Z', 'M7 20.662V19a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v1.662']);
  static const utensils = LucideIcon('utensils', ['M3 2v7c0 1.1.9 2 2 2h4a2 2 0 0 0 2-2V2', 'M7 2v20', 'M21 15V2a5 5 0 0 0-5 5v6c0 1.1.9 2 2 2h3Zm0 0v7']);
  static const slidersHorizontal = LucideIcon('sliders-horizontal', ['M21 4L14 4', 'M10 4L3 4', 'M21 12L12 12', 'M8 12L3 12', 'M21 20L16 20', 'M12 20L3 20', 'M14 2L14 6', 'M8 10L8 14', 'M16 18L16 22']);
  static const logOut = LucideIcon('log-out', ['M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4', 'M16 17L21 12L16 7', 'M21 12L9 12']);
  static const chevronRight = LucideIcon('chevron-right', ['m9 18 6-6-6-6']);
  static const chevronLeft = LucideIcon('chevron-left', ['m15 18-6-6 6-6']);
  static const arrowLeft = LucideIcon('arrow-left', ['m12 19-7-7 7-7', 'M19 12H5']);
  static const plus = LucideIcon('plus', ['M5 12h14', 'M12 5v14']);
  static const minus = LucideIcon('minus', ['M5 12h14']);
  static const x = LucideIcon('x', ['M18 6 6 18', 'm6 6 12 12']);
  static const search = LucideIcon('search', ['M3 11a8 8 0 1 0 16 0a8 8 0 1 0 -16 0Z', 'm21 21-4.3-4.3']);
  static const searchX = LucideIcon('search-x', ['m13.5 8.5-5 5', 'm8.5 8.5 5 5', 'M3 11a8 8 0 1 0 16 0a8 8 0 1 0 -16 0Z', 'm21 21-4.3-4.3']);
  static const phone = LucideIcon('phone', ['M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z']);
  static const mail = LucideIcon('mail', ['M4 4h16a2 2 0 0 1 2 2v12a2 2 0 0 1 -2 2h-16a2 2 0 0 1 -2 -2v-12a2 2 0 0 1 2 -2Z', 'm22 7-8.97 5.7a1.94 1.94 0 0 1-2.06 0L2 7']);
  static const cake = LucideIcon('cake', ['M20 21v-8a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8', 'M4 16s.5-1 2-1 2.5 2 4 2 2.5-2 4-2 2.5 2 4 2 2-1 2-1', 'M2 21h20', 'M7 8v3', 'M12 8v3', 'M17 8v3', 'M7 4h.01', 'M12 4h.01', 'M17 4h.01']);
  static const user = LucideIcon('user', ['M19 21v-2a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v2', 'M8 7a4 4 0 1 0 8 0a4 4 0 1 0 -8 0Z']);
  static const contact = LucideIcon('contact', ['M16 2v2', 'M7 22v-2a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v2', 'M8 2v2', 'M9 11a3 3 0 1 0 6 0a3 3 0 1 0 -6 0Z', 'M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2Z']);
  static const phoneCall = LucideIcon('phone-call', ['M22 16.92v3a2 2 0 0 1-2.18 2 19.79 19.79 0 0 1-8.63-3.07 19.5 19.5 0 0 1-6-6 19.79 19.79 0 0 1-3.07-8.67A2 2 0 0 1 4.11 2h3a2 2 0 0 1 2 1.72 12.84 12.84 0 0 0 .7 2.81 2 2 0 0 1-.45 2.11L8.09 9.91a16 16 0 0 0 6 6l1.27-1.27a2 2 0 0 1 2.11-.45 12.84 12.84 0 0 0 2.81.7A2 2 0 0 1 22 16.92z', 'M14.05 2a9 9 0 0 1 8 7.94', 'M14.05 6A5 5 0 0 1 18 10']);
  static const mapPin = LucideIcon('map-pin', ['M20 10c0 4.993-5.539 10.193-7.399 11.799a1 1 0 0 1-1.202 0C9.539 20.193 4 14.993 4 10a8 8 0 0 1 16 0', 'M9 10a3 3 0 1 0 6 0a3 3 0 1 0 -6 0Z']);
  static const calendarDays = LucideIcon('calendar-days', ['M8 2v4', 'M16 2v4', 'M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2Z', 'M3 10h18', 'M8 14h.01', 'M12 14h.01', 'M16 14h.01', 'M8 18h.01', 'M12 18h.01', 'M16 18h.01']);
  static const store = LucideIcon('store', ['m2 7 4.41-4.41A2 2 0 0 1 7.83 2h8.34a2 2 0 0 1 1.42.59L22 7', 'M4 12v8a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2v-8', 'M15 22v-4a2 2 0 0 0-2-2h-2a2 2 0 0 0-2 2v4', 'M2 7h20', 'M22 7v3a2 2 0 0 1-2 2a2.7 2.7 0 0 1-1.59-.63.7.7 0 0 0-.82 0A2.7 2.7 0 0 1 16 12a2.7 2.7 0 0 1-1.59-.63.7.7 0 0 0-.82 0A2.7 2.7 0 0 1 12 12a2.7 2.7 0 0 1-1.59-.63.7.7 0 0 0-.82 0A2.7 2.7 0 0 1 8 12a2.7 2.7 0 0 1-1.59-.63.7.7 0 0 0-.82 0A2.7 2.7 0 0 1 4 12a2 2 0 0 1-2-2V7']);
  static const pencil = LucideIcon('pencil', ['M21.174 6.812a1 1 0 0 0-3.986-3.987L3.842 16.174a2 2 0 0 0-.5.83l-1.321 4.352a.5.5 0 0 0 .623.622l4.353-1.32a2 2 0 0 0 .83-.497z', 'm15 5 4 4']);
  static const trash2 = LucideIcon('trash-2', ['M3 6h18', 'M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6', 'M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2', 'M10 11L10 17', 'M14 11L14 17']);
  static const refreshCw = LucideIcon('refresh-cw', ['M3 12a9 9 0 0 1 9-9 9.75 9.75 0 0 1 6.74 2.74L21 8', 'M21 3v5h-5', 'M21 12a9 9 0 0 1-9 9 9.75 9.75 0 0 1-6.74-2.74L3 16', 'M8 16H3v5']);
  static const cloudUpload = LucideIcon('cloud-upload', ['M12 13v8', 'M4 14.899A7 7 0 1 1 15.71 8h1.79a4.5 4.5 0 0 1 2.5 8.242', 'm8 17 4-4 4 4']);
  static const info = LucideIcon('info', ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z', 'M12 16v-4', 'M12 8h.01']);
  static const triangleAlert = LucideIcon('triangle-alert', ['m21.73 18-8-14a2 2 0 0 0-3.48 0l-8 14A2 2 0 0 0 4 21h16a2 2 0 0 0 1.73-3', 'M12 9v4', 'M12 17h.01']);
  static const check = LucideIcon('check', ['M20 6 9 17l-5-5']);
  static const flame = LucideIcon('flame', ['M8.5 14.5A2.5 2.5 0 0 0 11 12c0-1.38-.5-2-1-3-1.072-2.143-.224-4.054 2-6 .5 2.5 2 4.9 4 6.5 2 1.6 3 3.5 3 5.5a7 7 0 1 1-14 0c0-1.153.433-2.294 1-3a2.5 2.5 0 0 0 2.5 2.5z']);
  static const play = LucideIcon('play', ['M6 3L20 12L6 21L6 3Z']);
  static const circlePlay = LucideIcon('circle-play', ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z', 'M10 8L16 12L10 16L10 8Z']);
  static const rotateCcw = LucideIcon('rotate-ccw', ['M3 12a9 9 0 1 0 9-9 9.75 9.75 0 0 0-6.74 2.74L3 8', 'M3 3v5h5']);
  static const arrowUp = LucideIcon('arrow-up', ['m5 12 7-7 7 7', 'M12 19V5']);
  static const arrowDown = LucideIcon('arrow-down', ['M12 5v14', 'm19 12-7 7-7-7']);
  static const arrowLeftRight = LucideIcon('arrow-left-right', ['M8 3 4 7l4 4', 'M4 7h16', 'm16 21 4-4-4-4', 'M20 17H4']);
  static const timer = LucideIcon('timer', ['M10 2L14 2', 'M12 14L15 11', 'M4 14a8 8 0 1 0 16 0a8 8 0 1 0 -16 0Z']);
  static const bookmark = LucideIcon('bookmark', ['m19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z']);
  static const bookmarkPlus = LucideIcon('bookmark-plus', ['m19 21-7-4-7 4V5a2 2 0 0 1 2-2h10a2 2 0 0 1 2 2v16z', 'M12 7L12 13', 'M15 10L9 10']);
  static const batteryLow = LucideIcon('battery-low', ['M4 7h12a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-6a2 2 0 0 1 2 -2Z', 'M22 11L22 13', 'M6 11L6 13']);
  static const batteryMedium = LucideIcon('battery-medium', ['M4 7h12a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-6a2 2 0 0 1 2 -2Z', 'M22 11L22 13', 'M6 11L6 13', 'M10 11L10 13']);
  static const batteryFull = LucideIcon('battery-full', ['M4 7h12a2 2 0 0 1 2 2v6a2 2 0 0 1 -2 2h-12a2 2 0 0 1 -2 -2v-6a2 2 0 0 1 2 -2Z', 'M22 11L22 13', 'M6 11L6 13', 'M10 11L10 13', 'M14 11L14 13']);
  static const trendingDown = LucideIcon('trending-down', ['M22 17L13.5 8.5L8.5 13.5L2 7', 'M16 17L22 17L22 11']);
  static const moveRight = LucideIcon('move-right', ['M18 8L22 12L18 16', 'M2 12H22']);
  static const bell = LucideIcon('bell', ['M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9', 'M10.3 21a1.94 1.94 0 0 0 3.4 0']);
  static const bellOff = LucideIcon('bell-off', ['M8.7 3A6 6 0 0 1 18 8a21.3 21.3 0 0 0 .6 5', 'M17 17H3s3-2 3-9a4.67 4.67 0 0 1 .3-1.7', 'M10.3 21a1.94 1.94 0 0 0 3.4 0', 'm2 2 20 20']);
  static const palette = LucideIcon('palette', ['M13 6.5a0.5 0.5 0 1 0 1 0a0.5 0.5 0 1 0 -1 0Z', 'M17 10.5a0.5 0.5 0 1 0 1 0a0.5 0.5 0 1 0 -1 0Z', 'M8 7.5a0.5 0.5 0 1 0 1 0a0.5 0.5 0 1 0 -1 0Z', 'M6 12.5a0.5 0.5 0 1 0 1 0a0.5 0.5 0 1 0 -1 0Z', 'M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10c.926 0 1.648-.746 1.648-1.688 0-.437-.18-.835-.437-1.125-.29-.289-.438-.652-.438-1.125a1.64 1.64 0 0 1 1.668-1.668h1.996c3.051 0 5.555-2.503 5.555-5.554C21.965 6.012 17.461 2 12 2z']);
  static const sun = LucideIcon('sun', ['M8 12a4 4 0 1 0 8 0a4 4 0 1 0 -8 0Z', 'M12 2v2', 'M12 20v2', 'm4.93 4.93 1.41 1.41', 'm17.66 17.66 1.41 1.41', 'M2 12h2', 'M20 12h2', 'm6.34 17.66-1.41 1.41', 'm19.07 4.93-1.41 1.41']);
  static const moon = LucideIcon('moon', ['M12 3a6 6 0 0 0 9 9 9 9 0 1 1-9-9Z']);
  static const inbox = LucideIcon('inbox', ['M22 12L16 12L14 15L10 15L8 12L2 12', 'M5.45 5.11 2 12v6a2 2 0 0 0 2 2h16a2 2 0 0 0 2-2v-6l-3.45-6.89A2 2 0 0 0 16.76 4H7.24a2 2 0 0 0-1.79 1.11z']);
  static const idCard = LucideIcon('id-card', ['M16 10h2', 'M16 14h2', 'M6.17 15a3 3 0 0 1 5.66 0', 'M7 11a2 2 0 1 0 4 0a2 2 0 1 0 -4 0Z', 'M4 5h16a2 2 0 0 1 2 2v10a2 2 0 0 1 -2 2h-16a2 2 0 0 1 -2 -2v-10a2 2 0 0 1 2 -2Z']);
  static const userRoundSearch = LucideIcon('user-round-search', ['M5 8a5 5 0 1 0 10 0a5 5 0 1 0 -10 0Z', 'M2 21a8 8 0 0 1 10.434-7.62', 'M15 18a3 3 0 1 0 6 0a3 3 0 1 0 -6 0Z', 'm22 22-1.9-1.9']);
  static const circle = LucideIcon('circle', ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z']);
  static const circleDot = LucideIcon('circle-dot', ['M2 12a10 10 0 1 0 20 0a10 10 0 1 0 -20 0Z', 'M11 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0Z']);
  static const ellipsisVertical = LucideIcon('ellipsis-vertical', ['M11 12a1 1 0 1 0 2 0a1 1 0 1 0 -2 0Z', 'M11 5a1 1 0 1 0 2 0a1 1 0 1 0 -2 0Z', 'M11 19a1 1 0 1 0 2 0a1 1 0 1 0 -2 0Z']);
  static const flag = LucideIcon('flag', ['M4 15s1-1 4-1 5 2 8 2 4-1 4-1V3s-1 1-4 1-5-2-8-2-4 1-4 1z', 'M4 22L4 15']);
  static const calendarCheck = LucideIcon('calendar-check', ['M8 2v4', 'M16 2v4', 'M5 4h14a2 2 0 0 1 2 2v14a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2v-14a2 2 0 0 1 2 -2Z', 'M3 10h18', 'm9 16 2 2 4-4']);
  static const footprints = LucideIcon('footprints', ['M4 16v-2.38C4 11.5 2.97 10.5 3 8c.03-2.72 1.49-6 4.5-6C9.37 2 10 3.8 10 5.5c0 3.11-2 5.66-2 8.68V16a2 2 0 1 1-4 0Z', 'M20 20v-2.38c0-2.12 1.03-3.12 1-5.62-.03-2.72-1.49-6-4.5-6C14.63 6 14 7.8 14 9.5c0 3.11 2 5.66 2 8.68V20a2 2 0 1 0 4 0Z', 'M16 17h4', 'M4 13h4']);
  static const chartColumn = LucideIcon('chart-column', ['M3 3v16a2 2 0 0 0 2 2h16', 'M18 17V9', 'M13 17V5', 'M8 17v-3']);
}

/// Draws a [LucideIcon] at stroke 2.75 with round caps and joins. Size and
/// color default to the ambient [IconTheme], so it works inside buttons and
/// the navigation bar like [Icon].
class AppIcon extends StatelessWidget {
  const AppIcon(this.icon, {super.key, this.size, this.color, this.semanticLabel});

  static const strokeWidth = 2.75;
  static const defaultSize = 22.0;

  final LucideIcon icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final s = size ?? theme.size ?? defaultSize;
    final c = color ?? theme.color ?? const Color(0xFF201E1D);
    final paint = SizedBox.square(
      dimension: s,
      child: CustomPaint(painter: _LucidePainter(icon, c.withValues(alpha: c.a * (theme.opacity ?? 1)))),
    );
    return semanticLabel == null
        ? ExcludeSemantics(child: paint)
        : Semantics(label: semanticLabel, child: ExcludeSemantics(child: paint));
  }
}

class _LucidePainter extends CustomPainter {
  _LucidePainter(this.icon, this.color);

  final LucideIcon icon;
  final Color color;

  static final _cache = <String, ui.Path>{};

  static ui.Path _path(LucideIcon icon) => _cache.putIfAbsent(icon.name, () {
        final path = ui.Path();
        final writer = _PathWriter(path);
        for (final d in icon.paths) {
          writeSvgPathDataToPath(d, writer);
        }
        return path;
      });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 24;
    canvas.scale(scale);
    canvas.drawPath(
      _path(icon),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = AppIcon.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_LucidePainter old) => old.icon != icon || old.color != color;
}

class _PathWriter extends PathProxy {
  _PathWriter(this.path);

  final ui.Path path;

  @override
  void moveTo(double x, double y) => path.moveTo(x, y);

  @override
  void lineTo(double x, double y) => path.lineTo(x, y);

  @override
  void cubicTo(double x1, double y1, double x2, double y2, double x3, double y3) =>
      path.cubicTo(x1, y1, x2, y2, x3, y3);

  @override
  void close() => path.close();
}
