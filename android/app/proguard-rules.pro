# Room creates generated database implementations from the database class
# name at runtime. Keep these names stable when R8 minification is enabled.
-keepnames class * extends androidx.room.RoomDatabase
-keep @androidx.room.Database class * { *; }
-keep class * extends androidx.room.RoomDatabase { *; }
