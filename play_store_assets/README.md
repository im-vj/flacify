# Google Play Store Assets

This directory contains assets needed for publishing Flacify on the Google Play Store.

## Required Assets

### 1. App Icon
- **Format**: PNG
- **Size**: 512x512 pixels
- **Path**: `assets/icons/app_icon.png`
- **Adaptive Icon**:
  - Foreground: `assets/icons/app_icon_foreground.png` (432x432)
  - Background: Solid color (#000000)

### 2. Feature Graphic
- **Format**: JPG or PNG
- **Size**: 1024x500 pixels
- **Location**: `play_store_assets/feature_graphics/`
- **Purpose**: Displayed at top of store listing

### 3. Screenshots
- **Phone Screenshots** (Required):
  - Format: PNG or JPG
  - Sizes: 1080x1920 or 1440x3040 pixels
  - Quantity: 2-8 screenshots
  - Location: `play_store_assets/screenshots/phone/`

- **7-inch Tablet Screenshots** (Optional):
  - Size: 1200x1920 pixels

- **10-inch Tablet Screenshots** (Optional):
  - Size: 1440x2560 pixels

### 4. Store Listing Text

#### Title
- **Maximum**: 50 characters
- **Example**: "Flacify - Self-Hosted Music Player"

#### Short Description
- **Maximum**: 80 characters
- **Example**: "Stream your music collection from any Navidrome server"

#### Full Description
- **Maximum**: 4000 characters
- Include:
  - Key features
  - How to use
  - Requirements (Navidrome server)
  - Privacy information

## Screenshot Content Suggestions

Create screenshots showing:
1. **Login Screen** - Server connection setup
2. **Home Screen** - Music library browsing
3. **Now Playing** - Music playback with controls
4. **Playlist Management** - Creating/editing playlists
5. **Search** - Finding music in your library
6. **Settings** - App configuration options
7. **Background Playback** - Notification controls
8. **Offline Mode** - Downloaded songs

## Design Guidelines

### Colors
- Primary: #000000 (Black)
- Accent: #00F0FF (Cyan) - from app theme
- Text: White on dark background

### Typography
- Use the app's font (Google Fonts: Roboto or similar)
- Keep text minimal and readable
- Highlight key features with icons

### App Store Optimization (ASO) Tips

1. **Keywords in Title**: Include "music player", "streaming", "self-hosted", "Navidrome"
2. **Localization**: Consider translating for key markets
3. **Video** (Optional): 30-120 second app preview video
4. **Promo Text**: 170 characters highlighting what's new in latest update
5. **Recent Changes**: Keep changelog updated for each release

## Generating Assets

1. Run the app on a physical device or emulator
2. Take screenshots using device screenshot function
3. Edit screenshots to add device frames (optional)
4. Resize to required dimensions
5. Optimize images for web (compress without quality loss)

## Updating Assets

When updating the app:
1. Update screenshots if UI changes significantly
2. Update feature graphic if branding changes
3. Keep app icon consistent for brand recognition
4. Update store text with new features

## Privacy & Compliance

- Ensure screenshots don't show personal data
- Use demo music library for screenshots
- Include privacy policy link in description
- Mention required permissions and why they're needed