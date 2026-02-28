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

// Global list for demo purposes
List<UserDetails> globalUserList = [
  UserDetails(id: "1", userName: "Adithvs", phoneNumber: "8138872364", email: "adith@gmail.com", password: "1234567", dob: "01/01/2000")
];

bool isLoggedIn = false; 
UserDetails? currentUser;
