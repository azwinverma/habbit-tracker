import 'package:flutter/material.dart';
import 'package:habit_tracker_nepali/widgets/ad_banner.dart';
import 'package:habit_tracker_nepali/widgets/extra_time_editior.dart';
import '../models/habit.dart';

class AddEditHabitScreen extends StatefulWidget {
  final Habit? habit;
  const AddEditHabitScreen({super.key, this.habit});

  @override
  State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
}

class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name;
  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  bool _enabled = true;
  List<String> _extraTimes = const [];

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.habit?.name ?? '');
    if (widget.habit != null) {
      _time = TimeOfDay(
        hour: widget.habit!.reminderHour,
        minute: widget.habit!.reminderMinute,
      );
      _enabled = widget.habit!.enabled;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null) setState(() => _time = t);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          AppBar(title: Text(widget.habit == null ? 'Add Habit' : 'Edit Habit')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(
                  labelText: 'Habit name (उदाहरण: पानी पिउने)',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),

              // Optional primary time (kept hidden in your UI previously)
              // Row(
              //   children: [
              //     Expanded(
              //       child: InputDecorator(
              //         decoration: const InputDecoration(
              //           labelText: 'Reminder time',
              //           border: OutlineInputBorder(),
              //         ),
              //         child: Text(
              //             '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
              //       ),
              //     ),
              //     const SizedBox(width: 8),
              //     ElevatedButton.icon(
              //       onPressed: _pickTime,
              //       icon: const Icon(Icons.schedule),
              //       label: const Text('Pick'),
              //     ),
              //   ],
              // ),

              Align(
                alignment: Alignment.centerLeft,
                child: Text('Reminder time'),
              ),
              const SizedBox(height: 8),
              ExtraTimesEditor(
                initial: widget.habit?.reminderTimes ?? const [],
                onChanged: (list) {
                  _extraTimes = list;
                },
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
                title: const Text('Enable reminder'),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(context, {
                      'name': _name.text.trim(),
                      'hour': _time.hour,
                      'minute': _time.minute,
                      'enabled': _enabled,
                      'reminderTimes': _extraTimes,
                    });
                  },
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),

      // IMPORTANT: do NOT mark AdBanner as const
      bottomNavigationBar: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            AdBanner(
              placement: 'add_edit_bottom',
              // optional padding
              // padding: EdgeInsets.only(top: 6, bottom: 8),
            ),
          ],
        ),
      ),
    );
  }
}






// import 'package:flutter/material.dart';
// import 'package:habit_tracker_nepali/widgets/ad_banner.dart';
// import 'package:habit_tracker_nepali/widgets/extra_time_editior.dart';
// import '../models/habit.dart';

// class AddEditHabitScreen extends StatefulWidget {
//   final Habit? habit;
//   const AddEditHabitScreen({super.key, this.habit});
//   @override
//   State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
// }

// class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _name;
//   TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
//   bool _enabled = true;
// List<String> _extraTimes = const [];

//   @override
//   void initState() {
//     super.initState();
//     _name = TextEditingController(text: widget.habit?.name ?? '');
//     if (widget.habit != null) {
//       _time = TimeOfDay(hour: widget.habit!.reminderHour, minute: widget.habit!.reminderMinute);
//       _enabled = widget.habit!.enabled;
//     }
//   }

//   @override
//   void dispose() { _name.dispose(); super.dispose(); }

//   Future<void> _pickTime() async {
//     final t = await showTimePicker(context: context, initialTime: _time);
//     if (t != null) setState(() => _time = t);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.habit == null ? 'Add Habit' : 'Edit Habit')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _name,
//                 decoration: const InputDecoration(labelText: 'Habit name (उदाहरण: पानी पिउने)', border: OutlineInputBorder()),
//                 validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
//               ),
//               const SizedBox(height: 12),
//               // Row(children: [
//               //   Expanded(
//               //     child: InputDecorator(
//               //       decoration: const InputDecoration(labelText: 'Reminder time', border: OutlineInputBorder()),
//               //       child: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
//               //     ),
//               //   ),
//               //   const SizedBox(width: 8),
//               //   ElevatedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule), label: const Text('Pick')),
//               // ]),
//               // const SizedBox(height: 12),
//               Align(
//                 alignment: Alignment.centerLeft,
//                 child: Text('Reminder time'),
//               ),
//               const SizedBox(height: 8),
//               ExtraTimesEditor(
//                 initial: widget.habit?.reminderTimes ?? const [],
//                 onChanged: (list) {
//                   // stash them in Navigator.pop result; see below
//                   _extraTimes = list;
//                 },
//               ),
//               const SizedBox(height: 12),
//               SwitchListTile(value: _enabled, onChanged: (v) => setState(() => _enabled = v), title: const Text('Enable reminder')),
//               const Spacer(),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (!_formKey.currentState!.validate()) return;
//                     // Navigator.pop(context, {
//                     //   'name': _name.text.trim(),
//                     //   'hour': _time.hour,
//                     //   'minute': _time.minute,
//                     //   'enabled': _enabled,
//                     // });
//                     Navigator.pop(context, {
//                       'name': _name.text.trim(),
//                       'hour': _time.hour,
//                       'minute': _time.minute,
//                       'enabled': _enabled,
//                       'reminderTimes': _extraTimes,
//                     });
//                   },
//                   child: const Text('Save'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//       bottomNavigationBar: SafeArea(
//   child: Column(
//     mainAxisSize: MainAxisSize.min,
//     children: const [
//       // Your existing FilledButton / controls can go above if needed
//       AdBanner(placement: 'reading_bottom', padding: EdgeInsets.only(top: 6, bottom: 8)),
//     ],
//   ),
// ),
//     );
//   }
// }
////////////////////////////////////////////////////////////////////////////////////////////


// import 'package:flutter/material.dart';
// import '../models/habit.dart';

// class AddEditHabitScreen extends StatefulWidget {
//   final Habit? habit;
//   const AddEditHabitScreen({super.key, this.habit});
//   @override
//   State<AddEditHabitScreen> createState() => _AddEditHabitScreenState();
// }

// class _AddEditHabitScreenState extends State<AddEditHabitScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _name;
//   TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
//   bool _enabled = true;

//   @override
//   void initState() {
//     super.initState();
//     _name = TextEditingController(text: widget.habit?.name ?? '');
//     if (widget.habit != null) {
//       _time = TimeOfDay(hour: widget.habit!.reminderHour, minute: widget.habit!.reminderMinute);
//       _enabled = widget.habit!.enabled;
//     }
//   }

//   @override
//   void dispose() {
//     _name.dispose();
//     super.dispose();
//   }

//   Future<void> _pickTime() async {
//     final t = await showTimePicker(context: context, initialTime: _time);
//     if (t != null) setState(() => _time = t);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(widget.habit == null ? 'Add Habit' : 'Edit Habit')),
//       body: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               TextFormField(
//                 controller: _name,
//                 decoration: const InputDecoration(labelText: 'Habit name (उदाहरण: पानी पिउने)', border: OutlineInputBorder()),
//                 validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
//               ),
//               const SizedBox(height: 12),
//               Row(children: [
//                 Expanded(
//                   child: InputDecorator(
//                     decoration: const InputDecoration(labelText: 'Reminder time', border: OutlineInputBorder()),
//                     child: Text('${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}'),
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 ElevatedButton.icon(onPressed: _pickTime, icon: const Icon(Icons.schedule), label: const Text('Pick')),
//               ]),
//               const SizedBox(height: 12),
//               SwitchListTile(value: _enabled, onChanged: (v) => setState(() => _enabled = v), title: const Text('Enable reminder (चालु)')),
//               const Spacer(),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () {
//                     if (!_formKey.currentState!.validate()) return;
//                     Navigator.pop(context, {
//                       'name': _name.text.trim(),
//                       'hour': _time.hour,
//                       'minute': _time.minute,
//                       'enabled': _enabled,
//                     });
//                   },
//                   child: const Text('Save'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }