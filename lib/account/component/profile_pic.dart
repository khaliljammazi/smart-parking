import 'package:flutter/material.dart';

class ProfilePic extends StatelessWidget {
  const ProfilePic({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 115,
      width: 115,
      child: CircleAvatar(
        backgroundImage: const NetworkImage(
          'https://cdn.pixabay.com/photo/2016/03/28/12/35/cat-1285634_1280.png',
        ),
      ),
    );
  }
}