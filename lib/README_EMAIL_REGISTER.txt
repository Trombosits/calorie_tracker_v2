PATCH: Email register + Google profile setup

Files to replace into C:\src\calorie_tracker_v2\lib\:
- main.dart
- register.dart

What changed:
1. Regular email register now stores profile data together with signUp metadata.
2. If Supabase Email confirmation is OFF, profile is inserted directly into public.users and user enters MainNavigation.
3. If Supabase Email confirmation is ON, user is sent back to LoginPage to verify email first. After verification + login, AuthGate creates the users row from auth.user_metadata.
4. Google users still go to RegisterPage(isGoogleSetup: true) when their profile is incomplete.

Supabase requirement:
- users table must have RLS policies allowing authenticated users to select/insert/update their own row:
  auth.uid() = id_user

For fastest development:
- Supabase Dashboard > Authentication > Providers > Email > turn OFF Confirm email.
