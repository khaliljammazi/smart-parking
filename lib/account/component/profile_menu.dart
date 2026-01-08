import 'package:flutter/material.dart';
import '../../utils/constanst.dart';

class ProfileMenu extends StatelessWidget {
  final String textData;
  final IconData iconData;
  final Widget? page;

  const ProfileMenu({Key? key, required this.textData, required this.iconData, this.page}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: page != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page!),
              );
            }
          : () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$textData - Bientôt disponible')),
              );
            },
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SizedBox(
          width: double.infinity,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 18.0),
                    child: Icon(iconData, color: AppColor.navy),
                  ),
                  Text(
                    textData,
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColor.forText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColor.navy,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}