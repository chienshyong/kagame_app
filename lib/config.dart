//import 'dart:io';
class Config {
  //For deployment
  static const String apiUrl = "http://35.198.254.232:80"; 
  
  //For development: 10.0.2.2 as special IP address that redirects to your emulator
  // static final String apiUrl = Platform.isIOS
  //     ? "http://127.0.0.1:8000"  // iOS Simulator
  //     : "http://10.0.2.2:8000";  // Android Emulator
}