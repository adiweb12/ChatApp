class UserDetails {
  final String id;
  final String userName;
  String phoneNumber;
  String email;
  String password; // Added password field which was missing
  final String dob;

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

class Message{
    final String id;
    final String sender;
    final String receiver;
    final String message;
    final String time;
    final String type;
    final bool isMe;
    
    Message({
        required this.id,
        required this.sender,
        required this.receiver,
        required this.message,
        required this.time,
        required this.type,
        required this.isMe,
    });
    
    Map<String, dynamic> toMap() {
        return{
            "id": id,
            "sender": sender,
            "receiver": receiver,
            "message": message,
            "time": time,
            "type": type,
        };
    }
}

// Global list for demo purposes
List<UserDetails> globalUserList = [];

bool isLoggedIn = false; 
UserDetails? currentUser;
