package io.github.moranetz.weighit.android.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface BoardDao {
    @Query("SELECT COUNT(*) FROM boards")
    suspend fun countBoards(): Int

    @Transaction
    @Query("SELECT * FROM boards ORDER BY updated_at DESC")
    fun observeBoards(): Flow<List<BoardWithRelations>>

    @Transaction
    @Query("SELECT * FROM boards WHERE id = :boardId LIMIT 1")
    suspend fun getBoard(boardId: String): BoardWithRelations?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertBoard(board: BoardEntity)

    @Update
    suspend fun updateBoard(board: BoardEntity)

    @Delete
    suspend fun deleteBoard(board: BoardEntity)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertHypothesis(hypothesis: HypothesisEntity)

    @Update
    suspend fun updateHypothesis(hypothesis: HypothesisEntity)

    @Query("DELETE FROM hypotheses WHERE id = :hypothesisId")
    suspend fun deleteHypothesis(hypothesisId: String)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insertEvidence(evidence: EvidenceEntity)

    @Update
    suspend fun updateEvidence(evidence: EvidenceEntity)

    @Query("DELETE FROM evidence WHERE id = :evidenceId")
    suspend fun deleteEvidence(evidenceId: String)

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsertCellRating(cellRating: CellRatingEntity)

    @Query("DELETE FROM cell_ratings WHERE id = :cellId")
    suspend fun deleteCellRating(cellId: String)

    @Query("DELETE FROM cell_ratings WHERE board_id = :boardId")
    suspend fun deleteRatingsForBoard(boardId: String)

    @Query("DELETE FROM cell_ratings WHERE evidence_id = :evidenceId")
    suspend fun deleteRatingsForEvidence(evidenceId: String)

    @Query("DELETE FROM cell_ratings WHERE hypothesis_id = :hypothesisId")
    suspend fun deleteRatingsForHypothesis(hypothesisId: String)
}
