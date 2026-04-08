// import 'package:easy_localization/easy_localization.dart';
// import 'package:flutter/material.dart';
//
// class LanguageSwitcher extends StatelessWidget {
//   const LanguageSwitcher({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final currentLocale = context.locale.languageCode;
//
//     return PopupMenuButton<Locale>(
//       tooltip: 'language'.tr(),
//       icon: const Icon(Icons.language),
//       onSelected: (locale) async {
//         if (locale != context.locale) {
//           await context.setLocale(locale);
//         }
//       },
//       itemBuilder: (context) => [
//         PopupMenuItem(
//           value: const Locale('en'),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.check,
//                 size: 18,
//                 color: currentLocale == 'en' ? null : Colors.transparent,
//               ),
//               const SizedBox(width: 8),
//               Text('english'.tr()),
//             ],
//           ),
//         ),
//         PopupMenuItem(
//           value: const Locale('ar'),
//           child: Row(
//             children: [
//               Icon(
//                 Icons.check,
//                 size: 18,
//                 color: currentLocale == 'ar' ? null : Colors.transparent,
//               ),
//               const SizedBox(width: 8),
//               Text('arabic'.tr()),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }


import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LanguageButton(
            label: 'English',
            selected: !isArabic,
            onTap: () async {
              if (!isArabic) return;
              await context.setLocale(const Locale('en'));
            },
          ),
          const SizedBox(width: 4),
          _LanguageButton(
            label: 'العربية',
            selected: isArabic,
            onTap: () async {
              if (isArabic) return;
              await context.setLocale(const Locale('ar'));
            },
          ),
        ],
      ),
    );
  }
}

class _LanguageButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selectedColor = Theme.of(context).colorScheme.primary;

    return Material(
      color: selected ? selectedColor : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.black : Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}