import 'dart:convert';
import 'dart:math';

import 'package:senior_project_hair_ai/preferences_provider.dart';
import 'package:senior_project_hair_ai/screens/capture.dart';
import 'package:senior_project_hair_ai/screens/work.dart';

const activeProfileUserIDPrefKey = 'active-profile-user-id';
const jsonUserProfilesPrefKey = 'json-user-profiles';

// See
// https://stackoverflow.com/a/13318269
final _rngRandom = Random();
int randomRange(int minInclusive, int maxExclusive) => minInclusive + _rngRandom.nextInt(maxExclusive - minInclusive);

class UserProfile {
  //String userID;
  String displayName;
  List<String> workItems;
  List<String> recentItems;

  // each user data is specific to
  UserProfile({required this.displayName})
      : workItems = [], recentItems = [];

  UserProfile.fromJson(Map<String, dynamic> json) :
      displayName = json['display-name'] as String,
      workItems = (json['work-items'] as List<dynamic>).cast<String>(),
      recentItems = (json['recent-items'] as List<dynamic>).cast<String>();

  String getAbbreviation() => displayName.split(' ').map((e) => e[0]).join().toUpperCase();

  static String getUniqueUserID(String displayName) {
    final baseUserID = displayName.toLowerCase().replaceAll(' ', '_');
    //late String uniqueUserID;
    //while (true) {
    for (var i=10000; i < 99999; i++) {
      // generate random numbers instead
      //final i = randomRange(10000, 99999);
      final uniqueUserID = '$baseUserID$i';
      if (!users.containsKey(uniqueUserID)) {
        return uniqueUserID;
      }
    }
    throw UnsupportedError('mostly unreachable');
  }

  static Map<String, dynamic> toJson(UserProfile value) =>
      {'display-name': value.displayName, 'work-items': value.workItems, 'recent-items': value.recentItems};

  static String toJsonString(UserProfile value) => jsonEncode(toJson(value));

  static Map<String, UserProfile> users = {};

  // TODO should save each time a modification is made
  static void load() {
    // TODO load defaults if failure
    final userProfileDefault = UserProfile(displayName: 'Bob Ross');
    final userID = getUniqueUserID(userProfileDefault.displayName);

    try {
      final json = jsonDecode(
          prefs.ensure<String>(jsonUserProfilesPrefKey)) as Map<String,
          dynamic>;
      users = json.map((key, value) =>
          MapEntry(key, UserProfile.fromJson(value as Map<String, dynamic>)));
    } catch (e) {
      // error doesnt really matter, just catch json or missing pref error

      users[userID] = userProfileDefault;
    }

    // activeProfileUserIDPrefKey
    final oldWorkItems = prefs.get<List<String>>(apiCachedWorkIDListPrefKey);
    if (oldWorkItems != null) {
      // migrate
      userProfileDefault.workItems = oldWorkItems;
      prefs.sharedPrefs.remove(apiCachedWorkIDListPrefKey); // remove old prefs
    }

    final oldRecentItems = prefs.get<List<String>>(recentsListPrefKey);
    if (oldRecentItems != null) {
      // migrate
      userProfileDefault.recentItems = oldRecentItems;
      prefs.sharedPrefs.remove(recentsListPrefKey); // remove old prefs
    }

    // This tests if the stated user id actually maps to an existing profile
    final statedUserID = prefs.getOrCreate(activeProfileUserIDPrefKey, userID);
    if (!users.containsKey(statedUserID)) {
      prefs.set(activeProfileUserIDPrefKey, userID);
    }

    // saving is redundant when above all successful
    save(); // save dummy defaults otherwise
  }

  static void save() {
    prefs.set(jsonUserProfilesPrefKey,
      jsonEncode(users, toEncodable: (Object? value) => value is UserProfile
        ? toJson(value)
        : throw UnsupportedError('Cannot convert to JSON: $value'),
      ),
    );
  }

  static UserProfile getActiveUserProfile() {
    return users[prefs.ensure(activeProfileUserIDPrefKey)]!;
  }

  // returns whether successful (collision or not)
  static bool createUser(String userID, String displayName) {
    var dup = true;
    users.putIfAbsent(userID, () {
      dup = false;
      return UserProfile(displayName: displayName);
    });
    if (!dup) {
      save(); // persistence
    }
    return !dup;
  }
}