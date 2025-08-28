# Darood App 🕌✨

A real-time, location-based Flutter application designed to connect Muslims around the world and promote the beautiful practice of reciting Darood (Salawat) upon Prophet Muhammad (ﷺ).

## 📖 Core Idea

The goal of the Darood App is to create a living, visual representation of Muslims sending blessings upon the Prophet. By showing users on a global map with their real-time Darood counts, the app aims to foster a sense of community, motivation, and spiritual connection. It's a reminder that at any given moment, thousands are united in this beautiful act of devotion.

## 🌟 Key Features

-   **Real-time Map View 🗺️:** See all app users as pins on a global map. Each pin displays a user's profile picture and their live Darood count.
-   **Live User Location 📍:** Your pin automatically updates to your current location, highlighting your presence in the global community.
-   **User Authentication 🔐:** Secure sign-up and login functionality powered by Supabase Auth.
-   **Live Darood Counter 🔢:** An interactive counter that updates your Darood count in the database in real-time.
-   **Dynamic User Profiles 👤:** Users can update their username, full name, and upload a profile picture to Supabase Storage.
-   **Location Search 🔍:** A search bar to explore different locations on the map.

## 🛠️ Tech Stack

### Frontend

-   **Framework:** 🐦 Flutter
-   **Mapping:** 🗺️ `flutter_map`
-   **Location:** 🛰️ `geolocator`
-   **State Management:** ⚙️ `StreamBuilder` & `StatefulWidget`
-   **Image Handling:** 🖼️ `image_picker`
-   **Networking:** 🌐 `http`

### Backend

-   **Service:** 🚀 **Supabase**
    -   **Database:** 🐘 PostgreSQL with PostGIS for location data.
    -   **Authentication:** 🔑 Supabase Auth
    -   **Real-time:** ⚡ Supabase Realtime for live map updates.
    -   **Storage:** 🗄️ Supabase Storage for user avatars.
    -   **Database Functions:** 🐘 `plpgsql` for efficient count increments.

## 🚀 Getting Started

To get a local copy up and running, follow these simple steps.

### Prerequisites

-   Flutter SDK installed.
-   A Supabase account and a new project created.

### 1. Backend Setup (Supabase)

This project requires a specific Supabase setup to function.

#### A. Run the SQL Setup Script

1.  In your Supabase project, navigate to the **SQL Editor**.
2.  Click **+ New query**.
3.  Copy and paste the entire script below and click **RUN**. This will create your `profiles` table, set up security policies, create a trigger for new users, and add the `increment_darood_count` function.

```sql
-- 1. Enable PostGIS Extension for location data
CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA extensions;

-- 2. Create the "profiles" table to store user data
CREATE TABLE public.profiles (
  id uuid NOT NULL REFERENCES auth.users ON DELETE CASCADE,
  username TEXT UNIQUE,
  full_name TEXT,
  avatar_url TEXT,
  darood_count INTEGER NOT NULL DEFAULT 0,
  location extensions.geometry(Point, 4326),
  PRIMARY KEY (id)
);
COMMENT ON TABLE public.profiles IS 'Profile data for each user, linked to auth.users.';

-- 3. Set up Row-Level Security (RLS)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public profiles are viewable by everyone."
  ON public.profiles FOR SELECT
  USING ( true );

CREATE POLICY "Users can insert their own profile."
  ON public.profiles FOR INSERT
  WITH CHECK ( auth.uid() = id );

CREATE POLICY "Users can update their own profile."
  ON public.profiles FOR UPDATE
  USING ( auth.uid() = id );

-- 4. Create a trigger to automatically create a profile for new users
CREATE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id)
  VALUES (new.id);
  RETURN new;
END;
$$;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- 5. Create the function to increment the darood_count
CREATE OR REPLACE FUNCTION increment_darood_count (user_id UUID, increment_value INT)
RETURNS VOID
LANGUAGE plpgsql
AS $$
BEGIN
  UPDATE public.profiles
  SET darood_count = darood_count + increment_value
  WHERE id = user_id;
END;
$$;
```

#### B. Create a Storage Bucket

1.  Go to the **Storage** section in Supabase.
2.  Create a new bucket named `avatars`.
3.  Make sure to turn on the **Public bucket** toggle.
4.  Set up the bucket policies to allow users to manage their own avatars (see Supabase docs for RLS on Storage).

### 2. Frontend Setup (Flutter)

#### A. Clone the repository
```sh
git clone https://github.com/your-username/darood_app.git
cd darood_app
flutter pub get
```
# C. Configure Supabase Credentials

- Open the file lib/main.dart.
- Find the Supabase.initialize() block.
- Replace the placeholder values with your actual Supabase URL and Anon Key from your project's API settings.

```
// lib/main.dart

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'YOUR_SUPABASE_URL',       // <-- PASTE YOUR URL HERE
    anonKey: 'YOUR_SUPABASE_ANON_KEY', // <-- PASTE YOUR ANON KEY HERE
  );

  runApp(const MyApp());
}
```
# **Configure Android & iOS Permissions**

```
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION" />
```
- iOS: Add the necessary location usage descriptions to ios/Runner/Info.plist.

# **Run the app**

```
flutter run
```

## 🙏 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any contributions you make are **greatly appreciated**.

If you have a suggestion that would make this better, please fork the repo and create a pull request. You can also simply open an issue with the tag "enhancement".

1.  Fork the Project
2.  Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3.  Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4.  Push to the Branch (`git push origin feature/AmazingFeature`)
5.  Open a Pull Request

## 📜 License

Distributed under the MIT License. See `LICENSE` for more information.
