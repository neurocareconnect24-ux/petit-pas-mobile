import 'package:flutter/material.dart';
import '../models/child.dart';
import '../data/i18n_data.dart';

class ChildModal extends StatefulWidget {
  final Child? initialChild;
  final Language currentLanguage;
  final Function(Child) onSave;

  const ChildModal({
    super.key,
    this.initialChild,
    required this.currentLanguage,
    required this.onSave,
  });

  @override
  State<ChildModal> createState() => _ChildModalState();
}

class _ChildModalState extends State<ChildModal> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late DateTime _birthDate;
  late Sex _sex;
  late bool _isPremature;
  int? _gestationalWeeks;
  late Language _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _name = widget.initialChild?.name ?? '';
    _birthDate = widget.initialChild?.birthDate ?? DateTime.now().subtract(const Duration(days: 365));
    _sex = widget.initialChild?.sex ?? Sex.male;
    _isPremature = widget.initialChild?.isPremature ?? false;
    _gestationalWeeks = widget.initialChild?.gestationalWeeks ?? 32;
    _selectedLanguage = widget.initialChild?.language ?? widget.currentLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final t = UiTranslations.all[_selectedLanguage] ?? UiTranslations.all[Language.fr]!;

    return AlertDialog(
      title: Text(widget.initialChild == null ? t.addChild : t.editChild),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                initialValue: _name,
                decoration: InputDecoration(
                  labelText: t.name,
                  border: const OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Requis' : null,
                onSaved: (val) => _name = val!.trim(),
              ),
              const SizedBox(height: 16),

              // Date de naissance
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.birthDate),
                subtitle: Text('${_birthDate.day}/${_birthDate.month}/${_birthDate.year}'),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _birthDate,
                    firstDate: DateTime(2018),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _birthDate = picked);
                  }
                },
              ),
              const SizedBox(height: 12),

              // Sexe (requis pour les courbes de croissance OMS)
              Text(_selectedLanguage == Language.fr ? 'Sexe' : 'Sexe / Sex',
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              const SizedBox(height: 4),
              SegmentedButton<Sex>(
                segments: [
                  ButtonSegment(value: Sex.male, label: Text(Sex.male.displayName(_selectedLanguage)), icon: const Icon(Icons.male, size: 18)),
                  ButtonSegment(value: Sex.female, label: Text(Sex.female.displayName(_selectedLanguage)), icon: const Icon(Icons.female, size: 18)),
                ],
                selected: {_sex},
                onSelectionChanged: (s) => setState(() => _sex = s.first),
              ),
              const SizedBox(height: 12),

              // Enfant prématuré
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.prematurity, style: const TextStyle(fontSize: 13)),
                value: _isPremature,
                onChanged: (val) => setState(() => _isPremature = val),
              ),

              if (_isPremature) ...[
                const SizedBox(height: 8),
                TextFormField(
                  initialValue: _gestationalWeeks?.toString(),
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: t.gestationalWeeks,
                    border: const OutlineInputBorder(),
                  ),
                  onSaved: (val) => _gestationalWeeks = int.tryParse(val ?? '32'),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.cancel),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4693D4),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              final child = Child(
                id: widget.initialChild?.id ?? 'child_${DateTime.now().millisecondsSinceEpoch}',
                name: _name,
                birthDate: _birthDate,
                sex: _sex,
                isPremature: _isPremature,
                gestationalWeeks: _gestationalWeeks,
                language: _selectedLanguage,
              );
              widget.onSave(child);
              Navigator.of(context).pop();
            }
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}
