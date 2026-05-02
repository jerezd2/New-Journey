# 🐻 New Journey

> **Discover, save, and experience the best places across New Jersey**

New Journey is a community-driven bucket list mobile application built with **Flutter** and **Supabase**. The application allows users to explore restaurants, scenic locations, activities, and hidden gems while tracking places they have visited or plan to visit.


# Authentication
- **Multi-step sign-up** : 4-step registration collecting personal info, address (live OpenStreetMap autocomplete API), username, password, and profile photo
- **Username-based login** : users log in with their username
- **Forgot password** : email-based password reset via Supabase Auth
- **Change password** : two-step flow verifying the current password before setting a new one
- **Two-Factor Authentication** : MFA support with Google Authenticator

# Home Screen
- **Grid layout** : Grid of place cards
- **Pull-to-refresh** : reload the feed with a swipe

# Search Bar
- **Live search** : real-time place lookup as you type 
- Results display the same Place Card used in the home feed

# Places
- **Add a new place** : upload a photo (camera or gallery), enter a name, select a category from the database, write a description, and optionally rate it
- **Place detail page** : full-screen image, name, description, like button, and community comments
- **Categories** 
# Likes
- **UI** : like/unlike updates instantly in the UI 
- Likes stored in the `likes` table

# Star Ratings
- **Star rating dialog** : tap to rate any place 1–5 stars

# Saved Posts 
- **Bookmark any place** : tap the bookmark icon on any place card

#  Profile
- **Instagram-style profile** : avatar, username, post/follower/following counts, location, bio, email, phone
- **Posts grid** : grid of the user's submitted places
- **Saved tab** : view all boards
- **Edit profile** : update name, username, phone, address, and avatar photo
- **Follow / Unfollow** : follow other users from their public profile 

# Settings
- Edit Profile
- Change Password
- Saved Posts
- Dark Mode toggle (persisted via `SharedPreferences`)
- Two-Factor Authentication toggle
- Account Privacy & Notifications (UI scaffolded)
- Log Out (with confirmation dialog)

# Dark Mode
- Full dark mode support across all screens
- Theme preference persisted between sessions 
---

# Tech Used

| Layer | Platform |
|---|---|
| Mobile Framework | Flutter (Dart) |
| Backend & Database | Supabase |
| Authentication | Supabase Auth (email/password + MFA) |
| Address Autocomplete | OpenStreetMap API |
| State Management | Flutter `setState` + `StatefulWidget` |

---

## Project Structure

```
lib/
├── main.dart                 
│
├── screens/
│   ├── auth_screen.dart        # Login 
│   ├── main_nav_screen.dart    # Bottom navigation 
│   ├── home_screen_ui.dart     # Grid feed, greeting header
│   ├── search_screen.dart      # Live search with PlaceCard results
│   ├── add_new_place_screen.dart # Add post + create list 
│   ├── post_detail_screen.dart # Place image, description, likes
│   ├── post_screen.dart        # Legacy post creation screen
│   ├── profile_screen.dart     # User profile, posts grid, saved boards
│   ├── edit_profile_screen.dart # Edit name, username, avatar, address
│   ├── settings_screen.dart    # Dark mode, 2FA, logout, account settings
│   ├── change_password.dart    # Two-step password change flow
│   ├── saved_posts_screen.dart # All saved posts grid with unsave
│   ├── saved_board_screen.dart # Posts saved to a specific board
│   ├── user_profile_screen.dart # Public profile 
│   ├── mfa_login_screen.dart   # Code entry at login
│   ├── mfa_setup_screen.dart   
│   └── places_screen.dart      # places screen
│
├── likes/
│   ├── likes_backend.dart      
│   └── like_button_ui.dart     
├── ratings/
│   ├── rating_service.dart    
│   ├── rating_dialog.dart      
│   ├── rating_display.dart   
│   └── rating_utils.dart      
├── widgets/
│   ├── place_card.dart         # Main place card with image, rating, like, bookmark
│   ├── app_button.dart        
│   ├── app_card.dart          
│   ├── app_screen.dart         
│   └── app_text_field.dart     
│
└── theme/
    ├── app_colors.dart          # Color 
    ├── app_text_styles.dart     # Text style 
    ├── app_spacing.dart         
    ├── app_radii.dart           
    └── app_theme.dart           
```


## Start

- [Flutter SDK]
- [Supabase]

### 1. Clone the repository
```bash
git clone https://github.com/jerezd2/New-Journey.git
cd New-Journey/new_journey
```

### 2. Install dependencies
```bash
flutter pub get
```

### 3. Configure Supabase
In `lib/main.dart`, the Supabase URL and anon key are already set. To use your own project, replace:

```dart
await Supabase.initialize(
  url: 'YOUROWN_SUPABASE_URL',
  anonKey: 'YOUROWN_SUPABASE_ANON_KEY',
);
```


### 4. Run the app
```bash
flutter run




| Name            | Role |
| Destiny Jerez   | Backend Developer |
| Karolina Szwarc | Backend Developer |
| Geena Armstrong | Backend Developer |
| Dania Aslam     | Frontend Developer|
| Ewurabena Amuah | Frontend Developer|
| Meliza Garcia   | Fontend Developer |


For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
