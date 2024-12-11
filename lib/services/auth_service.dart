import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  //sign in with google
  signInWithGoogle() async {
    // start google sign in process
    final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();
    //take authentication details from google
    final GoogleSignInAuthentication gAuth = await gUser!.authentication;
    // make login credentials
    final credential = GoogleAuthProvider.credential(
      accessToken: gAuth.accessToken,
      idToken: gAuth.idToken,
    );
    //log in
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }
}
