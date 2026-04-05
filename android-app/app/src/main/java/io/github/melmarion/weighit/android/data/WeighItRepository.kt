package io.github.melmarion.weighit.android.data

import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

class WeighItRepository(
    private val boardDao: BoardDao
) {
    suspend fun hasBoards(): Boolean = boardDao.countBoards() > 0

    fun observeBoards(): Flow<List<BoardSnapshot>> =
        boardDao.observeBoards().map { boards ->
            boards.map { BoardSnapshot(it.board, it.hypotheses, it.evidence, it.cellRatings) }
        }

    suspend fun createBoard(example: Boolean = false): String {
        val boardId = java.util.UUID.randomUUID().toString()
        val now = System.currentTimeMillis()
        val board = if (example) {
            BoardEntity(
                id = boardId,
                question = "Why did our latest product launch underperform?",
                createdAt = now,
                updatedAt = now
            )
        } else {
            BoardEntity(id = boardId, createdAt = now, updatedAt = now)
        }
        boardDao.insertBoard(board)

        if (example) {
            val h1 = HypothesisEntity(boardId = boardId, name = "Marketing didn't reach the right audience", colorHex = HypothesisColors.all[0], sortOrder = 0)
            val h2 = HypothesisEntity(boardId = boardId, name = "The product has usability issues", colorHex = HypothesisColors.all[1], sortOrder = 1)
            val h3 = HypothesisEntity(boardId = boardId, name = "Pricing is too high for the market", colorHex = HypothesisColors.all[2], sortOrder = 2)
            listOf(h1, h2, h3).forEach { hypothesis ->
                boardDao.insertHypothesis(hypothesis)
            }

            val e1 = EvidenceEntity(boardId = boardId, text = "Social media impressions were up 40%", credibility = Weight.HIGH.rawValue, relevance = Weight.HIGH.rawValue, sortOrder = 0)
            val e2 = EvidenceEntity(boardId = boardId, text = "Support tickets doubled in the first week", credibility = Weight.HIGH.rawValue, relevance = Weight.HIGH.rawValue, sortOrder = 1)
            val e3 = EvidenceEntity(boardId = boardId, text = "Competitors priced 20% lower", credibility = Weight.MEDIUM.rawValue, relevance = Weight.HIGH.rawValue, sortOrder = 2)
            val e4 = EvidenceEntity(boardId = boardId, text = "Users who finished onboarding had great retention", credibility = Weight.MEDIUM.rawValue, relevance = Weight.MEDIUM.rawValue, sortOrder = 3)
            listOf(e1, e2, e3, e4).forEach { evidence ->
                boardDao.insertEvidence(evidence)
            }

            listOf(
                CellRatingEntity(boardId = boardId, evidenceId = e1.id, hypothesisId = h1.id, ratingValue = Rating.CONTRADICTS.rawValue, note = "Impressions up = marketing DID reach people"),
                CellRatingEntity(boardId = boardId, evidenceId = e2.id, hypothesisId = h2.id, ratingValue = Rating.STRONGLY_SUPPORTS.rawValue, note = "Support tickets = confused users"),
                CellRatingEntity(boardId = boardId, evidenceId = e3.id, hypothesisId = h3.id, ratingValue = Rating.STRONGLY_SUPPORTS.rawValue),
                CellRatingEntity(boardId = boardId, evidenceId = e3.id, hypothesisId = h1.id, ratingValue = Rating.IRRELEVANT.rawValue),
                CellRatingEntity(boardId = boardId, evidenceId = e4.id, hypothesisId = h2.id, ratingValue = Rating.CONTRADICTS.rawValue, note = "Good retention after onboarding → maybe onboarding issue, not product")
            ).forEach { cellRating ->
                boardDao.upsertCellRating(cellRating)
            }
        } else {
            listOf(
                HypothesisEntity(boardId = boardId, colorHex = HypothesisColors.all[0], sortOrder = 0),
                HypothesisEntity(boardId = boardId, colorHex = HypothesisColors.all[1], sortOrder = 1)
            ).forEach { hypothesis ->
                boardDao.insertHypothesis(hypothesis)
            }
            boardDao.insertEvidence(EvidenceEntity(boardId = boardId, sortOrder = 0))
        }

        return boardId
    }

    suspend fun updateBoard(board: BoardEntity) = boardDao.updateBoard(board.copy(updatedAt = System.currentTimeMillis()))

    suspend fun deleteBoard(snapshot: BoardSnapshot) {
        boardDao.deleteRatingsForBoard(snapshot.board.id)
        snapshot.hypotheses.forEach { boardDao.deleteHypothesis(it.id) }
        snapshot.evidence.forEach { boardDao.deleteEvidence(it.id) }
        boardDao.deleteBoard(snapshot.board)
    }

    suspend fun upsertHypothesis(hypothesis: HypothesisEntity) {
        boardDao.insertHypothesis(hypothesis)
        touchBoard(hypothesis.boardId)
    }

    suspend fun deleteHypothesis(boardId: String, hypothesisId: String) {
        boardDao.deleteRatingsForHypothesis(hypothesisId)
        boardDao.deleteHypothesis(hypothesisId)
        touchBoard(boardId)
    }

    suspend fun upsertEvidence(evidence: EvidenceEntity) {
        boardDao.insertEvidence(evidence)
        touchBoard(evidence.boardId)
    }

    suspend fun deleteEvidence(boardId: String, evidenceId: String) {
        boardDao.deleteRatingsForEvidence(evidenceId)
        boardDao.deleteEvidence(evidenceId)
        touchBoard(boardId)
    }

    suspend fun setCell(boardId: String, evidenceId: String, hypothesisId: String, rating: Rating?, note: String? = null) {
        val existing = boardDao.getBoard(boardId)?.cellRatings?.firstOrNull { it.evidenceId == evidenceId && it.hypothesisId == hypothesisId }
        when {
            existing != null -> {
                val updated = existing.copy(
                    ratingValue = rating?.rawValue ?: existing.ratingValue,
                    note = note ?: existing.note
                )
                if (updated.ratingValue == null && updated.note.isBlank()) {
                    boardDao.deleteCellRating(updated.id)
                } else {
                    boardDao.upsertCellRating(updated)
                }
            }

            rating != null || !note.isNullOrBlank() -> {
                boardDao.upsertCellRating(
                    CellRatingEntity(
                        boardId = boardId,
                        evidenceId = evidenceId,
                        hypothesisId = hypothesisId,
                        ratingValue = rating?.rawValue,
                        note = note.orEmpty()
                    )
                )
            }
        }
        touchBoard(boardId)
    }

    suspend fun clearRating(boardId: String, evidenceId: String, hypothesisId: String) {
        val existing = boardDao.getBoard(boardId)?.cellRatings?.firstOrNull { it.evidenceId == evidenceId && it.hypothesisId == hypothesisId } ?: return
        if (existing.note.isBlank()) {
            boardDao.deleteCellRating(existing.id)
        } else {
            boardDao.upsertCellRating(existing.copy(ratingValue = null))
        }
        touchBoard(boardId)
    }

    private suspend fun touchBoard(boardId: String) {
        val current = boardDao.getBoard(boardId)?.board ?: return
        boardDao.updateBoard(current.copy(updatedAt = System.currentTimeMillis()))
    }
}
