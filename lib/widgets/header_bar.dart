import 'package:flutter/material.dart';
import '../models/child.dart';
import '../data/i18n_data.dart';
import 'package:url_launcher/url_launcher.dart';

class HeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final List<Child> childrenList;
  final Child activeChild;
  final Function(String) onSelectChild;
  final VoidCallback onOpenAddChild;
  final VoidCallback onOpenEditChild;
  final Function(Language) onLanguageChange;

  const HeaderBar({
    super.key,
    required this.childrenList,
    required this.activeChild,
    required this.onSelectChild,
    required this.onOpenAddChild,
    required this.onOpenEditChild,
    required this.onLanguageChange,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80.0);

  @override
  Widget build(BuildContext context) {
    final t = UiTranslations.all[activeChild.language] ?? UiTranslations.all[Language.fr]!;

    return AppBar(
      backgroundColor: const Color(0xFFFFFFFF), // Color sand-100
      elevation: 1,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset('assets/logo_icon.jpg', width: 24, height: 24, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.appTitle,
                style: const TextStyle(
                  color: Color(0xFF141414),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text(
                t.subtitle,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // Bouton Communauté WhatsApp
        IconButton(
          icon: const Icon(Icons.group, color: Color(0xFF4693D4)),
          tooltip: 'Rejoindre la communauté',
          onPressed: () async {
            final url = Uri.parse('https://chat.whatsapp.com/LfrEYRQXuhO10XwGtT7fQx'); 
            if (await canLaunchUrl(url)) {
              await launchUrl(url, mode: LaunchMode.externalApplication);
            }
          },
        ),
        const SizedBox(width: 8),

        // Sélecteur d'enfant active
        PopupMenuButton<String>(
          onSelected: (id) {
            if (id == 'add_new') {
              onOpenAddChild();
            } else if (id == 'edit_current') {
              onOpenEditChild();
            } else {
              onSelectChild(id);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.face, color: Color(0xFF4693D4), size: 18),
                const SizedBox(width: 6),
                Text(
                  activeChild.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF141414),
                    fontSize: 13,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
          itemBuilder: (context) => [
            ...childrenList.map(
              (c) => PopupMenuItem(
                value: c.id,
                child: Row(
                  children: [
                    Icon(
                      Icons.check,
                      color: c.id == activeChild.id ? const Color(0xFF4693D4) : Colors.transparent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(c.name),
                  ],
                ),
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'edit_current',
              child: Row(
                children: [
                  const Icon(Icons.edit_outlined, color: Color(0xFF4693D4), size: 18),
                  const SizedBox(width: 8),
                  Text(t.editChild),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'add_new',
              child: Row(
                children: [
                  const Icon(Icons.add, color: Color(0xFF4693D4), size: 18),
                  const SizedBox(width: 8),
                  Text(t.addChild),
                ],
              ),
            ),
          ],
        ),

        // Sélecteur de langue (FR, Fon, Yoruba)
        PopupMenuButton<Language>(
          onSelected: onLanguageChange,
          icon: const Icon(Icons.language, color: Color(0xFF141414)),
          itemBuilder: (context) => Language.values
              .map(
                (lang) => PopupMenuItem(
                  value: lang,
                  child: Text(lang.displayName),
                ),
              )
              .toList(),
        ),
        const SizedBox(width: 8),
      ],
    );
  }
}
