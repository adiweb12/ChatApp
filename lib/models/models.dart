class UserDetails {
  final String id;
  final String userName;
  String phoneNumber;
  String email;
  String password; // Added password field which was missing
  String dob;

  UserDetails({
    required this.id,
    required this.userName,
    required this.phoneNumber,
    required this.email,
    required this.password,
    required this.dob,
  });
}

class SyncedContact {
  final String id;
  final String currentUserPhone; // The account this contact belongs to
  final String userName;
  final String phoneNumber;

  SyncedContact({
    required this.id,
    required this.currentUserPhone,
    required this.userName,
    required this.phoneNumber,
  });
}


// Global list for demo purposes
List<UserDetails> globalUserList = [];

bool isLoggedIn = false; 
UserDetails? currentUser;
