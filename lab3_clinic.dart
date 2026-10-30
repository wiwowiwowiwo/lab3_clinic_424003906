// Lab 3: ANB Health Center Appointment Tracker 
import 'dart:io';

// COLORS 
class Ansi {
  static const reset = '\x1B[0m';
  static const red = '\x1B[31m';
  static const green = '\x1B[32m';
  static const yellow = '\x1B[33m';
  static const blue = '\x1B[34m';
  static const magenta = '\x1B[35m';
  static const cyan = '\x1B[36m';
}

// Thrown for expected clinic problems (bad input, full doctor, wrong ID).
class ClinicException implements Exception {
  final String message;
  ClinicException(this.message);

  @override
  String toString() => message;
}

// Thrown when the user types 0 to go back.
class ActionCancelled implements Exception {}

// Date guidance
const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
];

// Example: Fri, Oct 30, 2026
String fmtDate(DateTime d) =>
    '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';

// Example: Fri, Oct 30, 2026 6:05 PM
String fmtDateTime(DateTime d) {
  final hour = d.hour % 12 == 0 ? 12 : d.hour % 12;
  final minute = d.minute.toString().padLeft(2, '0');
  final ampm = d.hour < 12 ? 'AM' : 'PM';
  return '${fmtDate(d)} $hour:$minute $ampm';
}

// Unique text key for one calendar day.
String dateKey(DateTime d) => '${d.year}-${d.month}-${d.day}';

// CLINIC CATALOG 
// One complaint and the department that handles it.
class Condition {
  final String name;
  final String department;
  const Condition(this.name, this.department);

  // Checks age and sex rules for the department.
  void checkEligibility(int age, String sex) {
    if (department == 'Pediatrics' && age > 17) {
      throw ClinicException(
          'Pediatric services are for patients 17 years old and below.');
    }
    if (department == 'OB-Gynecology' && sex != 'Female') {
      throw ClinicException('OB-Gynecology services are for female patients.');
    }
  }
}

// Fixed lists of departments and complaints.
class Catalog {
  static const departments = [
    'General Medicine',
    'Pediatrics',
    'Orthopedics',
    'Cardiology',
    'Dermatology',
    'OB-Gynecology',
    'Dentistry',
    'ENT',
    'Ophthalmology',
  ];

  static const conditions = [
    Condition('Fever and cough', 'General Medicine'),
    Condition('High blood pressure', 'General Medicine'),
    Condition('Diabetes check-up', 'General Medicine'),
    Condition('Stomach pain and diarrhea', 'General Medicine'),
    Condition('General check-up and medical certificate', 'General Medicine'),
    Condition('Child fever and cough', 'Pediatrics'),
    Condition('Child vaccination', 'Pediatrics'),
    Condition('Child growth monitoring', 'Pediatrics'),
    Condition('Bone fracture', 'Orthopedics'),
    Condition('Joint or knee pain', 'Orthopedics'),
    Condition('Back pain', 'Orthopedics'),
    Condition('Sprain or muscle strain', 'Orthopedics'),
    Condition('Chest pain', 'Cardiology'),
    Condition('Heart palpitations', 'Cardiology'),
    Condition('Heart disease follow-up', 'Cardiology'),
    Condition('Skin rash', 'Dermatology'),
    Condition('Acne treatment', 'Dermatology'),
    Condition('Skin allergy', 'Dermatology'),
    Condition('Prenatal check-up', 'OB-Gynecology'),
    Condition('Family planning', 'OB-Gynecology'),
    Condition("Women's health check-up", 'OB-Gynecology'),
    Condition('Toothache', 'Dentistry'),
    Condition('Tooth extraction', 'Dentistry'),
    Condition('Dental cleaning', 'Dentistry'),
    Condition('Ear pain', 'ENT'),
    Condition('Sore throat', 'ENT'),
    Condition('Sinusitis', 'ENT'),
    Condition('Blurred vision', 'Ophthalmology'),
    Condition('Eye infection', 'Ophthalmology'),
    Condition('Eye check-up and glasses', 'Ophthalmology'),
  ];

  // Finds a complaint by its exact name.
  static Condition find(String name) =>
      conditions.firstWhere((c) => c.name == name);

  // Reasons shown when cancelling (the last one asks for typed text).
  static const cancelReasons = [
    'Patient feels better',
    'Schedule conflict',
    'Transportation problem',
    'Transferred to another clinic',
    'Doctor unavailable',
    'Others (please specify)',
  ];
}

// INPUT VALIDATORS 
// Turns text into a number, digits only.
int parseDigits(String raw) {
  final text = raw.trim();
  if (text.isEmpty) throw ClinicException('Please enter a number.');
  if (!RegExp(r'^\d+$').hasMatch(text)) {
    throw ClinicException(
        'Numbers must be digits only (no letters, spaces or symbols).');
  }
  if (text.length > 9) throw ClinicException('That number is too long.');
  return int.parse(text);
}

// Digits only and inside a range.
int parseNumber(String raw, int min, int max) {
  final n = parseDigits(raw);
  if (n < min || n > max) {
    throw ClinicException('Please choose a number from $min to $max.');
  }
  return n;
}

// Capitalizes each word
String toTitleCase(String text) {
  return text.replaceAllMapped(RegExp(r'[A-Za-z\u00D1\u00F1]+'), (m) {
    final word = m[0]!;
    return word[0].toUpperCase() + word.substring(1).toLowerCase();
  });
}

// Checks a person's name (spaces, symbols, numbers, length).
String validateName(String raw) {
  final text = raw.trim();
  if (text.isEmpty) throw ClinicException('Name cannot be empty.');
  if (text.contains('  ')) {
    throw ClinicException('Name must not contain double spaces.');
  }
  if (RegExp(r'\d').hasMatch(text)) {
    throw ClinicException('Name must not contain numbers.');
  }
  if (!RegExp(r"^[A-Za-z\u00D1\u00F1 .'\-]+$").hasMatch(text)) {
    throw ClinicException(
        "Name may only have letters, spaces, hyphen (-), apostrophe (') and period (.).");
  }
  if (!RegExp(r"^[A-Za-z\u00D1\u00F1]+\.?(?:[ '\-][A-Za-z\u00D1\u00F1]+\.?)*$")
      .hasMatch(text)) {
    throw ClinicException(
        'Invalid name format. Check for misplaced symbols (e.g. Ashley Nicole Belamide).');
  }
  final letters = text.replaceAll(RegExp(r'[^A-Za-z\u00D1\u00F1]'), '');
  if (letters.length < 2) {
    throw ClinicException('Name must have at least 2 letters.');
  }
  if (text.length > 50) {
    throw ClinicException('Name must be 50 characters or less.');
  }
  return toTitleCase(text);
}

// Age must be digits only from 0 to 120.
int validateAge(String raw) {
  final text = raw.trim();
  if (text.isEmpty) throw ClinicException('Age cannot be empty.');
  if (!RegExp(r'^\d+$').hasMatch(text)) {
    throw ClinicException(
        'Age must be digits only (no letters, spaces or symbols).');
  }
  if (text.length > 3 || int.parse(text) > 120) {
    throw ClinicException('Age must be between 0 and 120.');
  }
  return int.parse(text);
}

// Philippine mobile number: 11 digits starting with 09.
String validateContact(String raw) {
  final text = raw.trim();
  if (!RegExp(r'^\d+$').hasMatch(text)) {
    throw ClinicException(
        'Contact number must be digits only (no spaces, dashes or symbols).');
  }
  if (text.length != 11 || !text.startsWith('09')) {
    throw ClinicException('Use an 11-digit mobile number starting with 09.');
  }
  return text;
}

// Cancellation reason typed by the user.
String validateReason(String raw) {
  final text = raw.trim();
  if (text.length < 3) {
    throw ClinicException('Reason must be at least 3 characters.');
  }
  if (text.length > 60) {
    throw ClinicException('Reason must be 60 characters or less.');
  }
  if (text.contains('  ')) {
    throw ClinicException('Reason must not contain double spaces.');
  }
  if (!RegExp(r"^[A-Za-z0-9 .,'\-]+$").hasMatch(text)) {
    throw ClinicException(
        'Reason may only have letters, numbers, spaces and . , - \' symbols.');
  }
  return text;
}

// Search text is either a name (letters) or a Patient ID (digits).
String validateSearch(String raw) {
  final text = raw.trim();
  if (text.isEmpty) throw ClinicException('Please type a name or Patient ID.');
  if (text.contains('  ')) {
    throw ClinicException('Search must not contain double spaces.');
  }
  if (RegExp(r'^\d+$').hasMatch(text)) return text;
  if (RegExp(r'\d').hasMatch(text)) {
    throw ClinicException(
        'Use letters only for a name, or digits only for a Patient ID.');
  }
  if (!RegExp(r"^[A-Za-z\u00D1\u00F1 .'\-]+$").hasMatch(text)) {
    throw ClinicException('Search has invalid symbols.');
  }
  return text;
}

// Gives any class the ability to print bordered, colored boxes and tables.
mixin BoxPrinter {
  // Word-wraps text; wrapped lines are indented by [indent] spaces.
  List<String> _wrap(String text, int width, {int indent = 0}) {
    final out = <String>[];
    final pad = ' ' * indent;
    var rest = text;
    while (rest.length > width) {
      var cut = rest.lastIndexOf(' ', width);
      if (cut <= pad.length) cut = width;
      out.add(rest.substring(0, cut).trimRight());
      rest = pad + rest.substring(cut).trimLeft();
    }
    out.add(rest);
    return out;
  }

  // Centers a title inside the box.
  String _center(String text, int width) {
    if (text.length >= width) return text.substring(0, width);
    final left = (width - text.length) ~/ 2;
    return (' ' * left + text).padRight(width);
  }

  // Prints a box; the line '--' draws a divider.
  void printBox(String title, List<String> lines, String color,
      {int width = 62}) {
    final inner = width - 2;
    final textWidth = inner - 2;
    final thick = '=' * inner;
    final thin = '-' * inner;

    print('$color+$thick+${Ansi.reset}');
    print('$color|${_center(title, inner)}|${Ansi.reset}');
    print('$color+$thin+${Ansi.reset}');
    for (final line in lines) {
      if (line == '--') {
        print('$color+$thin+${Ansi.reset}');
        continue;
      }
      final colon = line.indexOf(': ');
      final indent = (colon >= 0 && colon <= 16) ? colon + 2 : 0;
      for (final part in _wrap(line, textWidth, indent: indent)) {
        print('$color| ${part.padRight(textWidth)} |${Ansi.reset}');
      }
    }
    print('$color+$thick+${Ansi.reset}');
  }

  // Prints a table with columns; long cells wrap onto more lines.
  void printTable(List<String> headers, List<int> widths,
      List<List<String>> rows, String color) {
    String rule(String ch) =>
        '+${widths.map((w) => ch * (w + 2)).join('+')}+';

    void printRow(List<String> cells) {
      final wrapped = <List<String>>[];
      for (var i = 0; i < widths.length; i++) {
        wrapped.add(_wrap(cells[i], widths[i]));
      }
      var height = 0;
      for (final c in wrapped) {
        if (c.length > height) height = c.length;
      }
      for (var line = 0; line < height; line++) {
        final parts = <String>[];
        for (var i = 0; i < widths.length; i++) {
          final text = line < wrapped[i].length ? wrapped[i][line] : '';
          parts.add(' ${text.padRight(widths[i])} ');
        }
        print('$color|${parts.join('|')}|${Ansi.reset}');
      }
    }

    print('$color${rule('=')}${Ansi.reset}');
    printRow(headers);
    print('$color${rule('=')}${Ansi.reset}');
    for (var i = 0; i < rows.length; i++) {
      printRow(rows[i]);
      print('$color${rule(i == rows.length - 1 ? '=' : '-')}${Ansi.reset}');
    }
  }
}

// Builds an aligned "Label        : value" line for boxes.
String field(String label, String value) => '${label.padRight(14)}: $value';

// ABSTRACT CLASS 
// Template for any person in the clinic. Cannot be created directly.
abstract class Person {
  final String name;
  final int age;

  Person(this.name, this.age);

  void display(); 
}

// INHERITANCE: Patient extends Person
class Patient extends Person with BoxPrinter {
  final int id;
  final String sex;
  final String contact;
  final Condition condition;
  final DateTime registeredOn;
  final List<Appointment> appointments = [];

  Patient(this.id, String name, int age, this.sex, this.contact, this.condition)
      : registeredOn = DateTime.now(),
        super(name, age);

  // The appointment that is still scheduled (or null).
  Appointment? get active {
    for (final a in appointments) {
      if (a.isActive) return a;
    }
    return null;
  }

  // The most recent appointment (or null).
  Appointment? get latest => appointments.isEmpty ? null : appointments.last;

  // Registered, Scheduled or Cancelled.
  String get status {
    final last = latest;
    if (last == null) return 'Registered';
    return last.isActive ? 'Scheduled' : 'Cancelled';
  }

  @override
  void display() {
    final last = latest;
    final color = last == null
        ? Ansi.yellow
        : (last.isActive ? Ansi.green : Ansi.red);

    final lines = <String>[
      field('Patient ID', '$id'),
      field('Name', name),
      field('Age / Sex', '$age / $sex'),
      field('Contact No.', contact),
      field('Complaint', condition.name),
      field('Department', condition.department),
      field('Registered On', fmtDateTime(registeredOn)),
      '--',
      field('Status', status.toUpperCase()),
    ];

    if (last == null) {
      lines.add('No appointment booked yet.');
    } else {
      lines.add(field('Doctor', 'Dr. ${last.doctor.name}'));
      lines.add(field('Dept.', last.doctor.department));
      lines.add(field('Queue No.', last.queueLabel));
      lines.add(field('Schedule', fmtDate(last.scheduleDate)));
      lines.add(field('Booked On', fmtDateTime(last.bookedOn)));
      if (!last.isActive) {
        lines.add(field('Cancel Reason', last.cancelReason ?? '-'));
        lines.add(field('Cancelled On', fmtDateTime(last.cancelledOn!)));
      }
    }
    printBox('PATIENT RECORD', lines, color);
  }
}

// INHERITANCE: Doctor extends Person 
class Doctor extends Person with BoxPrinter {
  final int id;
  final String department;
  final int maxSlots; 
  final Map<String, int> _booked = {}; 

  Doctor(this.id, String name, int age, this.department, {this.maxSlots = 3})
      : super(name, age);

  // Complaints this doctor's department treats.
  List<Condition> get treats =>
      Catalog.conditions.where((c) => c.department == department).toList();

  bool handles(Condition c) => c.department == department;
  int bookedOn(DateTime d) => _booked[dateKey(d)] ?? 0;
  int slotsLeftOn(DateTime d) => maxSlots - bookedOn(d);
  bool isFullOn(DateTime d) => slotsLeftOn(d) <= 0;

  // Takes one slot on that date.
  void book(DateTime d) => _booked[dateKey(d)] = bookedOn(d) + 1;

  // Frees one slot on that date.
  void release(DateTime d) {
    final left = bookedOn(d) - 1;
    _booked[dateKey(d)] = left < 0 ? 0 : left;
  }

  @override
  void display() {
    final today = DateTime.now();
    final taken = bookedOn(today);
    final left = slotsLeftOn(today);
    final bar = '[${'#' * taken}${'.' * left}]'; 
    printBox(
      'DOCTOR #$id',
      [
        field('Name', 'Dr. $name'),
        field('Department', department),
        field('Treats', treats.map((c) => c.name).join(', ')),
        field('Slots Today', '$bar $left of $maxSlots open'),
      ],
      Ansi.cyan,
    );
  }
}

// Appointment record 
enum AppointmentStatus { scheduled, cancelled }

class Appointment with BoxPrinter {
  final int queueNumber;
  final Patient patient;
  final Doctor doctor;
  final DateTime scheduleDate;
  final DateTime bookedOn;
  AppointmentStatus status = AppointmentStatus.scheduled;
  String? cancelReason;
  DateTime? cancelledOn;

  Appointment(this.queueNumber, this.patient, this.doctor, this.scheduleDate)
      : bookedOn = DateTime.now();

  bool get isActive => status == AppointmentStatus.scheduled;
  String get queueLabel => '#${queueNumber.toString().padLeft(3, '0')}';

  // Marks the appointment as cancelled.
  void cancel(String reason) {
    status = AppointmentStatus.cancelled;
    cancelReason = reason;
    cancelledOn = DateTime.now();
  }

  void display() {
    final lines = <String>[
      field('Patient ID', '${patient.id}'),
      field('Patient', patient.name),
      field('Complaint', patient.condition.name),
      '--',
      field('Doctor', 'Dr. ${doctor.name}'),
      field('Department', doctor.department),
      field('Schedule', fmtDate(scheduleDate)),
      field('Booked On', fmtDateTime(bookedOn)),
    ];
    if (!isActive) {
      lines.add('--');
      lines.add(field('Status', 'CANCELLED'));
      lines.add(field('Cancel Reason', cancelReason ?? '-'));
      lines.add(field('Cancelled On', fmtDateTime(cancelledOn!)));
    }
    printBox(
      isActive ? 'QUEUE TICKET $queueLabel' : 'CANCELLED TICKET $queueLabel',
      lines,
      isActive ? Ansi.green : Ansi.red,
    );
  }
}

// Simulated delay (Future + async/await) 
Future<void> loading(String message) async {
  stdout.write('${Ansi.blue}$message');
  for (var i = 0; i < 3; i++) {
    await Future.delayed(Duration(milliseconds: 500)); 
    stdout.write('.');
  }
  print(Ansi.reset);
}

// Main system class 
class HealthCenter with BoxPrinter {
  String name; 
  final List<Patient> patients = [];
  final List<Doctor> doctors = [];
  final List<Appointment> appointments = [];
  int _nextPatientId = 424086;
  int _nextQueue = 1;

  HealthCenter(this.name);

  // Pretend we are loading records from a server.
  Future<void> loadData() async {
    await loading('  Loading clinic data');
    doctors.addAll([
      Doctor(1, 'Ashley Bella', 45, 'General Medicine', maxSlots: 4),
      Doctor(2, 'Nico Yelsh', 41, 'Orthopedics', maxSlots: 3),
      Doctor(3, 'Ley Cole', 38, 'Pediatrics', maxSlots: 4),
      Doctor(4, 'Belatrix Shani', 52, 'Cardiology', maxSlots: 2),
      Doctor(5, 'Elocine Maleb', 36, 'Dermatology', maxSlots: 3),
      Doctor(6, 'Ashela Mibeni', 44, 'OB-Gynecology', maxSlots: 3),
      Doctor(7, 'Marco Dizon', 39, 'Dentistry', maxSlots: 3),
      Doctor(8, 'Rina Valdez', 47, 'ENT', maxSlots: 2),
      Doctor(9, 'Paolo Sarmiento', 50, 'General Medicine', maxSlots: 4),
      Doctor(10, 'Clara Mendoza', 43, 'Ophthalmology', maxSlots: 2),
    ]);
    registerPatient('Maria Cruz', 34, 'Female', '09171234567',
        Catalog.find('Fever and cough'));
    registerPatient('Jun Dela Pena', 52, 'Male', '09181234567',
        Catalog.find('High blood pressure'));
    registerPatient('Ana Reyes', 8, 'Female', '09191234567',
        Catalog.find('Child vaccination'));
  }

  // Creates a patient with the next automatic ID.
  Patient registerPatient(
      String name, int age, String sex, String contact, Condition condition) {
    final patient = Patient(_nextPatientId++, name, age, sex, contact, condition);
    patients.add(patient);
    return patient;
  }

  Patient findPatient(int id) {
    for (final p in patients) {
      if (p.id == id) return p;
    }
    throw ClinicException('No patient found with ID $id.');
  }

  // Doctors whose department treats this complaint.
  List<Doctor> doctorsFor(Condition c) =>
      doctors.where((d) => d.handles(c)).toList();

  List<Appointment> get activeAppointments =>
      appointments.where((a) => a.isActive).toList();

  List<Appointment> get cancelledAppointments =>
      appointments.where((a) => !a.isActive).toList();

  // Digits search by Patient ID, letters search by name.
  List<Patient> searchPatients(String keyword) {
    final isId = RegExp(r'^\d+$').hasMatch(keyword);
    final lower = keyword.toLowerCase();
    return patients
        .where((p) =>
            isId ? p.id.toString().contains(keyword) : p.name.toLowerCase().contains(lower))
        .toList();
  }

  // Async: simulates checking a slow database.
  Future<Appointment> bookAppointment(
      Patient patient, Doctor doctor, DateTime date) async {
    await loading('  Checking Dr. ${doctor.name}\'s schedule');

    if (patient.active != null) {
      throw ClinicException('${patient.name} already has an active appointment.');
    }
    if (!doctor.handles(patient.condition)) {
      throw ClinicException(
          'Dr. ${doctor.name} does not treat "${patient.condition.name}".');
    }
    if (doctor.isFullOn(date)) {
      throw ClinicException(
          'Dr. ${doctor.name} is fully booked on ${fmtDate(date)}.');
    }

    doctor.book(date);
    final appt = Appointment(_nextQueue++, patient, doctor, date);
    appointments.add(appt);
    patient.appointments.add(appt);
    return appt;
  }

  // Async: cancels an active appointment and frees the slot.
  Future<Appointment> cancelAppointment(int queueNumber, String reason) async {
    await loading('  Cancelling appointment');
    for (final a in appointments) {
      if (a.queueNumber == queueNumber && a.isActive) {
        a.cancel(reason);
        a.doctor.release(a.scheduleDate); 
        return a;
      }
    }
    throw ClinicException('No active appointment with queue number #$queueNumber.');
  }

  void showMenu() {
    print('');
    printBox(
      name.toUpperCase(),
      [
        '1. Register new patient',
        '2. View all patients',
        '3. View doctors and departments',
        '4. Book an appointment',
        '5. View appointments',
        '6. Cancel an appointment',
        '7. Search patient (name or Patient ID)',
        '0. Exit',
      ],
      Ansi.magenta,
      width: 56,
    );
  }

  // Table of the given patients.
  void showPatientTable(List<Patient> list) {
    printTable(
      ['Patient ID', 'Name', 'Age', 'Complaint', 'Status'],
      [10, 18, 3, 22, 10],
      [
        for (final p in list)
          [p.id.toString(), p.name, p.age.toString(), p.condition.name, p.status]
      ],
      Ansi.yellow,
    );
  }

  // Table of doctors with department and conditions treated.
  void showDoctorTable() {
    printTable(
      ['ID', 'Doctor', 'Department', 'Conditions Treated'],
      [2, 18, 15, 32],
      [
        for (final d in doctors)
          [
            d.id.toString(),
            'Dr. ${d.name}',
            d.department,
            d.treats.map((c) => c.name).join(', ')
          ]
      ],
      Ansi.cyan,
    );
  }

  // Table of appointments to pick from.
  void showAppointmentTable(List<Appointment> list) {
    printTable(
      ['Queue', 'Patient ID', 'Patient', 'Doctor', 'Schedule'],
      [5, 10, 16, 16, 16],
      [
        for (final a in list)
          [
            a.queueLabel,
            a.patient.id.toString(),
            a.patient.name,
            'Dr. ${a.doctor.name}',
            fmtDate(a.scheduleDate)
          ]
      ],
      Ansi.green,
    );
  }

  void showSummary() {
    print('');
    printBox(
      "TODAY'S SUMMARY",
      [
        field('Patients', '${patients.length} registered'),
        field('Scheduled', '${activeAppointments.length} appointment(s)'),
        field('Cancelled', '${cancelledAppointments.length} appointment(s)'),
        field('Doctors', '${doctors.length} on duty'),
        field('Departments', '${Catalog.departments.length}'),
      ],
      Ansi.blue,
    );
  }
}

void say(String message, String color) {
  print('$color$message${Ansi.reset}');
}

String readText(String prompt) {
  stdout.write(prompt);
  final line = stdin.readLineSync();
  if (line == null) {
    say('\n  Input closed. Exiting...', Ansi.red);
    exit(0);
  }
  return line;
}

T readValidated<T>(String prompt, T Function(String) parse) {
  while (true) {
    try {
      return parse(readText(prompt));
    } on ClinicException catch (e) {
      say('  ! ${e.message}', Ansi.red);
    }
  }
}

// Asks for a whole number inside a range.
int readNumber(String prompt, {required int min, required int max}) =>
    readValidated(prompt, (raw) => parseNumber(raw, min, max));

// Asks for 1..max; typing 0 goes back.
int pick(String prompt, int max) {
  final n = readNumber(prompt, min: 0, max: max);
  if (n == 0) throw ActionCancelled();
  return n;
}

// Asks a yes/no question.
bool readYesNo(String prompt) => readValidated(prompt, (raw) {
      final v = raw.trim().toLowerCase();
      if (v == 'y' || v == 'yes') return true;
      if (v == 'n' || v == 'no') return false;
      throw ClinicException('Please type Y or N.');
    });

// Prints complaints grouped by department.
void printComplaintMenu() {
  say('\n  Select the patient\'s complaint:', Ansi.yellow);
  for (final dept in Catalog.departments) {
    say('\n  $dept', Ansi.cyan);
    for (var i = 0; i < Catalog.conditions.length; i++) {
      final c = Catalog.conditions[i];
      if (c.department == dept) say('   [${i + 1}] ${c.name}', Ansi.yellow);
    }
  }
  print('');
}

void registerFlow(HealthCenter center) {
  say('\n  --- Patient Registration (type 0 at a menu to cancel) ---',
      Ansi.yellow);
  final name = readValidated('  Full name      : ', validateName);
  final age = readValidated('  Age            : ', validateAge);

  say('  Sex: [1] Male  [2] Female', Ansi.yellow);
  final sex = pick('  Select sex     : ', 2) == 1 ? 'Male' : 'Female';

  final contact =
      readValidated('  Contact number : ', validateContact);

  printComplaintMenu();
  final condition =
      readValidated('  Complaint no. (0 = cancel) : ', (raw) {
    final n = parseNumber(raw, 0, Catalog.conditions.length);
    if (n == 0) throw ActionCancelled();
    final c = Catalog.conditions[n - 1];
    c.checkEligibility(age, sex);
    return c;
  });

  final patient = center.registerPatient(name, age, sex, contact, condition);
  say('\n  Patient registered! Assigned Patient ID: ${patient.id}', Ansi.green);
  patient.display();
}

void viewPatients(HealthCenter center) {
  if (center.patients.isEmpty) {
    say('\n  No patients yet.', Ansi.red);
    return;
  }
  say('\n  Total patients: ${center.patients.length}', Ansi.yellow);
  center.showPatientTable(center.patients);
  say('  Tip: use option 7 to see a full patient record.', Ansi.blue);
}

void viewDoctors(HealthCenter center) {
  say('\n  Doctors on duty: ${center.doctors.length}', Ansi.cyan);
  center.showDoctorTable();
}

void viewAppointments(HealthCenter center) {
  final active = center.activeAppointments;
  final cancelled = center.cancelledAppointments;
  if (active.isEmpty && cancelled.isEmpty) {
    say('\n  No appointments yet.', Ansi.red);
    return;
  }
  say('\n  Scheduled appointments: ${active.length}', Ansi.green);
  for (final a in active) {
    a.display();
  }
  if (cancelled.isNotEmpty) {
    say('\n  Cancelled appointments: ${cancelled.length}', Ansi.red);
    for (final a in cancelled) {
      a.display();
    }
  }
}

void searchFlow(HealthCenter center) {
  say('\n  --- Search Patient ---', Ansi.yellow);
  final keyword =
      readValidated('  Name or Patient ID : ', validateSearch);
  final results = center.searchPatients(keyword);
  if (results.isEmpty) {
    say('  No patient matches "$keyword".', Ansi.red);
    return;
  }
  say('\n  Found ${results.length} record(s):', Ansi.green);
  for (final p in results) {
    p.display();
  }
}

Future<void> bookFlow(HealthCenter center) async {
  if (center.patients.isEmpty) {
    throw ClinicException('Register a patient first (option 1).');
  }
  final eligible = center.patients.where((p) => p.active == null).toList();
  if (eligible.isEmpty) {
    throw ClinicException('All patients already have an active appointment.');
  }

  say('\n  --- Book an Appointment ---', Ansi.green);
  center.showPatientTable(eligible);

  // Patient must exist and have no active appointment.
  final patient = readValidated('  Enter Patient ID (0 = cancel) : ', (raw) {
    final id = parseDigits(raw);
    if (id == 0) throw ActionCancelled();
    final p = center.findPatient(id);
    if (p.active != null) {
      throw ClinicException('${p.name} already has an active appointment.');
    }
    return p;
  });

  say('\n  Complaint : ${patient.condition.name}', Ansi.yellow);
  say('  Department: ${patient.condition.department}', Ansi.yellow);

  // Only doctors that treat this complaint are shown.
  final options = center.doctorsFor(patient.condition);
  if (options.isEmpty) {
    throw ClinicException('No doctor available for this complaint.');
  }
  say('\n  Available doctors:', Ansi.cyan);
  for (var i = 0; i < options.length; i++) {
    final d = options[i];
    say('   [${i + 1}] Dr. ${d.name} - ${d.department}', Ansi.cyan);
  }
  final doctor =
      options[pick('  Select doctor (0 = cancel) : ', options.length) - 1];
  doctor.display();

  // Next 5 days are open for booking.
  final now = DateTime.now();
  final days = List.generate(
      5, (i) => DateTime(now.year, now.month, now.day + i));
  say('\n  Available dates:', Ansi.cyan);
  for (var i = 0; i < days.length; i++) {
    final left = doctor.slotsLeftOn(days[i]);
    final info = left > 0 ? '$left slot(s) left' : 'FULL';
    say('   [${i + 1}] ${fmtDate(days[i])}  ($info)', Ansi.cyan);
  }
  final date = readValidated('  Select date (0 = cancel) : ', (raw) {
    final n = parseNumber(raw, 0, days.length);
    if (n == 0) throw ActionCancelled();
    final d = days[n - 1];
    if (doctor.isFullOn(d)) {
      throw ClinicException(
          'Dr. ${doctor.name} is fully booked on ${fmtDate(d)}. Choose another date.');
    }
    return d;
  });

  final appt = await center.bookAppointment(patient, doctor, date);
  say('\n  Booking confirmed!', Ansi.green);
  appt.display();
}

Future<void> cancelFlow(HealthCenter center) async {
  final active = center.activeAppointments;
  if (active.isEmpty) {
    throw ClinicException('There are no appointments to cancel.');
  }

  say('\n  --- Cancel an Appointment ---', Ansi.red);
  center.showAppointmentTable(active);

  final queueNo = readValidated('  Enter queue number (0 = cancel) : ', (raw) {
    final n = parseDigits(raw);
    if (n == 0) throw ActionCancelled();
    if (!active.any((a) => a.queueNumber == n)) {
      throw ClinicException('No active appointment with queue number #$n.');
    }
    return n;
  });

  say('\n  Reason for cancellation:', Ansi.yellow);
  for (var i = 0; i < Catalog.cancelReasons.length; i++) {
    say('   [${i + 1}] ${Catalog.cancelReasons[i]}', Ansi.yellow);
  }
  final choice = pick('  Select reason (0 = cancel) : ', Catalog.cancelReasons.length);
  var reason = Catalog.cancelReasons[choice - 1];
  if (choice == Catalog.cancelReasons.length) {
    reason = readValidated('  Type the reason : ', validateReason); 
  }

  if (!readYesNo('  Cancel ticket #$queueNo? (Y/N) : ')) {
    throw ActionCancelled();
  }

  final removed = await center.cancelAppointment(queueNo, reason);
  say('\n  Cancelled ticket ${removed.queueLabel} for ${removed.patient.name}.',
      Ansi.green);
  removed.patient.display();
}

Future<void> main() async {
  final center = HealthCenter('ANB Health Center');

  print('');
  say('  Welcome to the ${center.name}!', Ansi.magenta);

  try {
    await center.loadData();
  } catch (e) {
    say('  Could not load data: $e', Ansi.red);
    return;
  }

  var running = true;
  while (running) {
    center.showMenu();
    final choice = readNumber('  Choose an action (0-7): ', min: 0, max: 7);

    try {
      switch (choice) {
        case 1:
          registerFlow(center);
          break;
        case 2:
          viewPatients(center);
          break;
        case 3:
          viewDoctors(center);
          break;
        case 4:
          await bookFlow(center);
          break;
        case 5:
          viewAppointments(center);
          break;
        case 6:
          await cancelFlow(center);
          break;
        case 7:
          searchFlow(center);
          break;
        case 0:
          running = false;
          break;
      }
    } on ActionCancelled {
      say('\n  Action cancelled.', Ansi.yellow);
    } on ClinicException catch (e) {
      say('\n  ! ${e.message}', Ansi.red);
    } catch (e) {
      say('\n  Unexpected error: $e', Ansi.red);
    }
  }

  center.showSummary();
  say('\n  System closed. Thank you for visiting our System! Godbless', Ansi.magenta);
}