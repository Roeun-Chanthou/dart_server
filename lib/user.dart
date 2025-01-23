class User {
  String firstName;
  String lastName;
  User({
    this.firstName = "",
    this.lastName = "",
  });

  void setFirstName(String value) {
    firstName = value;
  }

  void setLastName(String value) {
    lastName = value;
  }
}
