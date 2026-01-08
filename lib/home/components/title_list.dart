import 'package:flutter/material.dart';
import '../../utils/constanst.dart';
import '../../utils/text/regular.dart';
import '../../utils/text/semi_bold.dart';

class TitleList extends StatelessWidget {
  final String title;
  final Widget? page;

  const TitleList({super.key, required this.title, this.page});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SemiBoldText(text: title, fontSize: 18, color: AppColor.forText),
        if (page != null)
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => page!),
              );
            },
            child: const RegularText(
              text: 'Voir tout',
              fontSize: 14,
              color: AppColor.navy,
            ),
          ),
      ],
    );
  }
}