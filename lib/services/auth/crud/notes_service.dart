// for sqlite database;

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' show join;
import 'package:path_provider/path_provider.dart';
import 'crud_exceptions.dart';
import 'package:sqflite/sqflite.dart';

class NoteService {
  Database? _db;

  List<DataBaseNotes> _notes = [];

  //creating a singleton
  static final NoteService _shared = NoteService._sharedInstance();
  NoteService._sharedInstance(){
    //initializing the late final _notesStreamController
    _notesStreamController = StreamController<List<DataBaseNotes>>.broadcast(
      onListen: () {
        _notesStreamController.sink.add(_notes); //making sure if theres a new listener, were also giving them the previous data too.
        //because streamcontoller doesnt do that by itself
      },
    );
  } //private constructor
  factory NoteService() => _shared;//factory constructor
  //done.

  //final _notesStreamController =
  //    StreamController<List<DataBaseNotes>>.broadcast(); //turning this into a late final, which means we need to make sure its initialized
  //when our instance is creates

  late final StreamController<List<DataBaseNotes>> _notesStreamController; //declaring it as a late final
     


  //getter for getting all the notes
  Stream<List<DataBaseNotes>> get allNotes => _notesStreamController.stream;

  Future<void> _cacheNotes() async {
    final allNotes = await getAllNotes(); //getAllNotes returns an iterable
    _notes = allNotes.toList();
    _notesStreamController
        .add(_notes); // adding the list of notes to the stream
  }

  // ------ ALL THE FUNCTIONALITIES ----- //
  /* delete all notes
      get allnotes
      update notes
      delete note
      create note
      get user
      create user
      get user or throw
      open
      close
  */

  Future<DataBaseUser> createOrGetUser({required String email}) async {
    try {
      final user = await getUser(email: email);
      return user;
    } on CouldNotFindUser {
      final createdUser = await createUser(email: email);
      return createdUser;
    } catch (e) {
      rethrow;
    }
  }

  Future<int> deleteAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDataBaseOrThrow();
    final numOfDel = await db.delete(noteTable);

    //deleting from cache
    _notes = [];
    _notesStreamController.add(_notes);

    return numOfDel;
  }

  Future<DataBaseNotes> updateNotes({
    required DataBaseNotes note,
    required String text,
  }) async {
    await _ensureDbIsOpen();
    final db = _getDataBaseOrThrow();
    await getNote(id: note.id); //making sure note exists
    final updatesCount = await db.update(noteTable, {
      textCol: text,
      isSyncedCol: 0,
    });
    if (updatesCount == 0) {
      throw CouldNotUpdateNote();
    } else {
      final updatedNote = await getNote(id: note.id);
      _notes.removeWhere((note) => note.id == updatedNote.id);
      _notes.add(updatedNote);
      _notesStreamController.add(_notes);
      return updatedNote;
    }
  }

  Future<Iterable<DataBaseNotes>> getAllNotes() async {
    await _ensureDbIsOpen();
    final db = _getDataBaseOrThrow();
    final notes = await db.query(noteTable);
    return notes.map((noteRow) => DataBaseNotes.fromRow(noteRow));
  }

  Future<DataBaseNotes> getNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDataBaseOrThrow();
    final notes = await db.query(
      noteTable,
      limit: 1,
      where: 'id=?',
      whereArgs: [id],
    );
    if (notes.isEmpty) {
      throw CouldNotFindNotes();
    } else {
      //here it is possible that the note thats required is prolly in the local cache but its just not updated
      //now is a good oppertunity to update the local cache.
      final note = DataBaseNotes.fromRow(notes.first);

      //updating
      _notes.removeWhere((note) => note.id == id);
      _notes.add(note);
      _notesStreamController.add(_notes);
      //done.

      return note;
    }
  }

  Future<void> deleteNote({required int id}) async {
    await _ensureDbIsOpen();
    final db = _getDataBaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id=?',
      whereArgs: [id],
    );
    if (deletedCount == 0) {
      throw CouldNotDeleteNote();
    } else {
      //removing the deleted note from the cache
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DataBaseNotes> createNote({required DataBaseUser owner}) async {
    await _ensureDbIsOpen();
    final db = _getDataBaseOrThrow();

    final dbUser = await getUser(email: owner.email);
    if (dbUser != owner) {
      throw CouldNotFindUser();
    } else {
      const text = '';
      final noteId = await db.insert(
        noteTable,
        {
          userIdCol: owner.id,
          textCol: text,
          isSyncedCol: 1,
        },
      );

      final note = DataBaseNotes(
        id: noteId,
        userId: owner.id,
        text: text,
        isSynced: true,
      );

      //reactivley adding the new notes to the database

      _notes.add(note);
      _notesStreamController.add(_notes);

      return note;
    }
  }

  Future<DataBaseUser> getUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDataBaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) {
      throw CouldNotFindUser();
    } else {
      return DataBaseUser.fromRow(results.first);
    }
  }

  Future<DataBaseUser> createUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDataBaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );
    if (results.isNotEmpty) {
      throw UserAlreadyExists();
    }
    final userId = await db.insert(userTable, {
      emailCol: email.toLowerCase(),
    });

    return DataBaseUser(
      id: userId,
      email: email,
    );
  }

  Future<void> deleteUser({required String email}) async {
    await _ensureDbIsOpen();
    final db = _getDataBaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email=?',
      whereArgs: [email.toLowerCase()],
    );
    if (deletedCount != 1) {
      throw CouldNotDeleteUser();
    }
  }

  Database _getDataBaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DataBaseIsNotOpen();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DataBaseIsNotOpen();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> _ensureDbIsOpen() async {
    //private function
    try {
      //our open function throws and exception if db is already open
      //we need to make sure that every time notes view is reloaded, a new db isnt created
      //and the exception wont get thrown everytime(kinda like a cycle)
      //to do that we
      await open();
    } on DataBasealreadyOpenException {
      //empty
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DataBasealreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, dbName);
      final db =
          await openDatabase(dbPath); //openDatabase is a sqflite API method
      _db = db;

      const createUserTable = ''' CREATE TABLE IF NOT EXISTS "user" (
              "id"	INTEGER NOT NULL,
              "email"	TEXT NOT NULL UNIQUE,
              PRIMARY KEY("id" AUTOINCREMENT)
            );''';

      await db.execute(createUserTable);

      const createNoteTable = ''' 
          CREATE TABLE "note" (
          "id"	INTEGER NOT NULL,
          "user_id"	INTEGER NOT NULL,
          "text"	TEXT,
          "is_synced"	INTEGER NOT NULL DEFAULT 0,
          PRIMARY KEY("id" AUTOINCREMENT),
          FOREIGN KEY("user_id") REFERENCES "user"("id")
        );''';

      await db.execute(createNoteTable);
      //we made sure the notes and the user data exists and now we need to cache that data
      await _cacheNotes();
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentDirectory();
    }
  }
}

@immutable
class DataBaseUser {
  final int id;
  final String email;

  const DataBaseUser({
    required this.id,
    required this.email,
  });

  DataBaseUser.fromRow(Map<String, Object?> map)
      : id = map[idCol] as int,
        email = map[emailCol] as String;

  @override
  String toString() => 'Person, id = $id, email = $email';

  @override
  bool operator ==(covariant DataBaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class DataBaseNotes {
  final int id;
  final int userId;
  final String text;
  final bool isSynced;

  DataBaseNotes({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSynced,
  });

  DataBaseNotes.fromRow(Map<String, Object?> map)
      : id = map[idCol] as int,
        userId = map[userIdCol] as int,
        text = map[textCol] as String,
        isSynced = (map[isSyncedCol] as int) == 1 ? true : false;

  @override
  String toString() =>
      'Note, ID = $id, UserID = $userId, isSynced = $isSynced, text = $text';

  @override
  bool operator ==(covariant DataBaseUser other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const dbName = 'notes.db';
const noteTable = 'note';
const userTable = 'user';
const idCol = 'id';
const emailCol = 'email';
const userIdCol = 'user_id';
const textCol = 'text';
const isSyncedCol = 'is_synced';
