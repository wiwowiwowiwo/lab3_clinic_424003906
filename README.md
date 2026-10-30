# ANB Health Center Appointment Tracker

A console-based clinic appointment system written in Dart.
Lab 3: Final Midterm Project - "The Dart App Simulator" (Dart Programming, Weeks 7-11).

**Author:** Ashley Nicole Belamide

## Features
- Register patients with validated input (name, age, sex, PH mobile number, complaint)
- View all patients and the doctors/departments table
- Book an appointment (doctor must treat the complaint, 5 selectable dates, limited slots per day)
- View scheduled and cancelled appointments as queue tickets
- Cancel an appointment with a reason (frees the doctor's slot)
- Search patients by name or Patient ID
- Type `0` at any menu to go back

## Requirements Covered
| Requirement | Where in the code |
|---|---|
| Abstract class | `Person` (abstract `display()`) |
| Inheritance | `Patient` and `Doctor` extend `Person` |
| Mixin | `BoxPrinter` (boxes/tables) used by `Patient`, `Doctor`, `Appointment`, `HealthCenter` |
| Constructors and methods | All classes |
| Future + async/await | `loading()`, `loadData()`, `bookAppointment()`, `cancelAppointment()`, `async main()` |
| Error handling | `try-catch` in `main()`, custom `ClinicException`, input validators |

## How to Run
This program reads keyboard input (`stdin`), so it needs a **local Dart SDK**.
It will not run in DartPad.

```bash
dart run bin/lab3_clinic.dart
```

Use a terminal that supports colors (VS Code terminal, Windows Terminal).

## Project Structure
```
bin/lab3_clinic.dart   # full application
pubspec.yaml
README.md
```