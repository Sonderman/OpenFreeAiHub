enum LocalStorageKeys {
  appOpenCount("appOpenCount"),
  welcomeDialogShown("welcomeDialogShown"),
  userPreferences("user_preferences"),
  mediaLibrary("media_library");

  final String value;
  const LocalStorageKeys(this.value);
}
