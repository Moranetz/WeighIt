package io.github.moranetz.weighit.android.data

import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [BoardEntity::class, HypothesisEntity::class, EvidenceEntity::class, CellRatingEntity::class],
    version = 1,
    exportSchema = false
)
abstract class WeighItDatabase : RoomDatabase() {
    abstract fun boardDao(): BoardDao
}
