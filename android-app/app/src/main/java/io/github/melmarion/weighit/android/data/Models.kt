package io.github.melmarion.weighit.android.data

import androidx.room.ColumnInfo
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.PrimaryKey
import androidx.room.Relation
import java.util.UUID
import kotlin.math.abs

enum class Rating(
    val rawValue: String,
    val label: String,
    val shortLabel: String,
    val value: Int
) {
    STRONGLY_SUPPORTS("CC", "Strong yes", "strongly supports", 2),
    SUPPORTS("C", "Supports", "supports", 1),
    IRRELEVANT("N", "Irrelevant", "irrelevant", 0),
    CONTRADICTS("I", "Contradicts", "contradicts", -1),
    STRONGLY_CONTRADICTS("II", "Strong no", "strongly contradicts", -2);

    companion object {
        fun fromRaw(raw: String?): Rating? = entries.firstOrNull { it.rawValue == raw }
    }
}

enum class Weight(
    val rawValue: String,
    val label: String,
    val multiplier: Double,
    val tip: String
) {
    HIGH("H", "High", 3.0, "Very trustworthy / highly relevant"),
    MEDIUM("M", "Med", 2.0, "Somewhat trustworthy / somewhat relevant"),
    LOW("L", "Low", 1.0, "Uncertain source / tangentially relevant");

    companion object {
        fun fromRaw(raw: String?): Weight = entries.firstOrNull { it.rawValue == raw } ?: MEDIUM
    }
}

@Entity(tableName = "boards")
data class BoardEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val question: String = "",
    val conclusion: String = "",
    @ColumnInfo(name = "created_at") val createdAt: Long = System.currentTimeMillis(),
    @ColumnInfo(name = "updated_at") val updatedAt: Long = System.currentTimeMillis()
)

@Entity(tableName = "hypotheses")
data class HypothesisEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "board_id", index = true) val boardId: String,
    val name: String = "",
    @ColumnInfo(name = "color_hex") val colorHex: String = "EF8B6E",
    @ColumnInfo(name = "is_ruled_out") val isRuledOut: Boolean = false,
    @ColumnInfo(name = "sort_order") val sortOrder: Int = 0
)

@Entity(tableName = "evidence")
data class EvidenceEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "board_id", index = true) val boardId: String,
    val text: String = "",
    val credibility: String = Weight.MEDIUM.rawValue,
    val relevance: String = Weight.MEDIUM.rawValue,
    @ColumnInfo(name = "sort_order") val sortOrder: Int = 0
)

@Entity(tableName = "cell_ratings")
data class CellRatingEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    @ColumnInfo(name = "board_id", index = true) val boardId: String,
    @ColumnInfo(name = "evidence_id", index = true) val evidenceId: String,
    @ColumnInfo(name = "hypothesis_id", index = true) val hypothesisId: String,
    @ColumnInfo(name = "rating_value") val ratingValue: String? = null,
    val note: String = ""
)

data class BoardWithRelations(
    @Embedded val board: BoardEntity,
    @Relation(parentColumn = "id", entityColumn = "board_id")
    val hypotheses: List<HypothesisEntity>,
    @Relation(parentColumn = "id", entityColumn = "board_id")
    val evidence: List<EvidenceEntity>,
    @Relation(parentColumn = "id", entityColumn = "board_id")
    val cellRatings: List<CellRatingEntity>
)

data class DiagnosticItem(
    val evidence: EvidenceEntity,
    val spread: Int
)

data class RankedHypothesis(
    val hypothesis: HypothesisEntity,
    val score: Int
)

data class BoardSnapshot(
    val board: BoardEntity,
    val hypotheses: List<HypothesisEntity>,
    val evidence: List<EvidenceEntity>,
    val cellRatings: List<CellRatingEntity>
) {
    val sortedHypotheses: List<HypothesisEntity> = hypotheses.sortedBy { it.sortOrder }
    val sortedEvidence: List<EvidenceEntity> = evidence.sortedBy { it.sortOrder }
    val activeHypotheses: List<HypothesisEntity> = sortedHypotheses.filterNot { it.isRuledOut }
    val ruledOutHypotheses: List<HypothesisEntity> = sortedHypotheses.filter { it.isRuledOut }
    val displayName: String = if (board.question.isBlank()) "Untitled board" else board.question.take(50)

    fun rating(evidenceId: String, hypothesisId: String): Rating? =
        Rating.fromRaw(cellRatings.firstOrNull { it.evidenceId == evidenceId && it.hypothesisId == hypothesisId }?.ratingValue)

    fun note(evidenceId: String, hypothesisId: String): String =
        cellRatings.firstOrNull { it.evidenceId == evidenceId && it.hypothesisId == hypothesisId }?.note.orEmpty()

    fun score(hypothesis: HypothesisEntity): Int? {
        if (hypothesis.isRuledOut) return null
        var total = 0.0
        sortedEvidence.forEach { item ->
            val rating = rating(item.id, hypothesis.id) ?: return@forEach
            total += rating.value * Weight.fromRaw(item.credibility).multiplier * Weight.fromRaw(item.relevance).multiplier
        }
        return total.toInt()
    }

    val rankedHypotheses: List<RankedHypothesis> =
        activeHypotheses.mapNotNull { hyp -> score(hyp)?.let { RankedHypothesis(hyp, it) } }.sortedByDescending { it.score }

    val maxAbsScore: Int = activeHypotheses.mapNotNull(::score).map(::abs).maxOrNull() ?: 1
    val totalCells: Int = activeHypotheses.size * sortedEvidence.size
    val filledCells: Int = cellRatings.count { it.ratingValue != null && activeHypotheses.any { hyp -> hyp.id == it.hypothesisId } }
    val completionPercent: Int = if (totalCells > 0) ((filledCells.toDouble() / totalCells.toDouble()) * 100).toInt() else 0

    val diagnostics: List<DiagnosticItem> = sortedEvidence.map { item ->
        val values = activeHypotheses.map { hyp -> rating(item.id, hyp.id)?.value ?: 0 }
        val spread = if (values.isEmpty()) 0 else ((values.maxOrNull() ?: 0) - (values.minOrNull() ?: 0))
        DiagnosticItem(item, spread)
    }.sortedByDescending { it.spread }

    val highDiagnostics: List<DiagnosticItem> = diagnostics.filter { it.spread >= 2 }
    val lowDiagnostics: List<DiagnosticItem> = diagnostics.filter { it.spread == 0 }

    val biasWarnings: List<String> = buildList {
        activeHypotheses.forEach { hyp ->
            val ratings = sortedEvidence.mapNotNull { rating(it.id, hyp.id) }
            if (ratings.size > 2 && ratings.all { it == Rating.STRONGLY_SUPPORTS || it == Rating.SUPPORTS }) {
                add("Everything supports \"${if (hyp.name.isBlank()) "one explanation" else hyp.name}\" — are you seeing what you want to see?")
            }
        }
        if (sortedEvidence.size < 3) add("Only a few data points. Could you be missing something?")
    }

    fun exportMarkdown(): String {
        val builder = StringBuilder("# Weigh It\n\n")
        if (board.question.isNotBlank()) {
            builder.append("**Question:** ").append(board.question).append("\n\n")
        }
        builder.append("## Explanations\n")
        sortedHypotheses.forEachIndexed { index, hypothesis ->
            val scoreText = score(hypothesis)?.let { if (it > 0) "+$it" else it.toString() } ?: "n/a"
            val prefix = if (hypothesis.isRuledOut) "~~" else ""
            val suffix = if (hypothesis.isRuledOut) "~~ (ruled out)" else ""
            builder.append(index + 1)
                .append(". ")
                .append(prefix)
                .append(if (hypothesis.name.isBlank()) "Unnamed" else hypothesis.name)
                .append(suffix)
                .append(" → score: ")
                .append(scoreText)
                .append("\n")
        }
        builder.append("\n## Evidence\n\n")
        sortedEvidence.forEach { item ->
            builder.append("**")
                .append(if (item.text.isBlank()) "Unnamed" else item.text)
                .append("** (trust: ")
                .append(Weight.fromRaw(item.credibility).label)
                .append(", relevance: ")
                .append(Weight.fromRaw(item.relevance).label)
                .append(")\n")
            sortedHypotheses.forEach hypothesisLoop@{ hypothesis ->
                val rating = rating(item.id, hypothesis.id) ?: return@hypothesisLoop
                val noteText = note(item.id, hypothesis.id)
                builder.append("  - vs. ")
                    .append(if (hypothesis.name.isBlank()) "?" else hypothesis.name)
                    .append(": ")
                    .append(rating.shortLabel)
                if (noteText.isNotBlank()) {
                    builder.append(" — \"").append(noteText).append("\"")
                }
                builder.append("\n")
            }
            builder.append("\n")
        }
        if (board.conclusion.isNotBlank()) {
            builder.append("## Conclusion\n\n").append(board.conclusion).append("\n\n")
        }
        builder.append("---\n_Weigh It — based on Analysis of Competing Hypotheses_\n")
        return builder.toString()
    }
}

object HypothesisColors {
    val all = listOf("EF8B6E", "5CC4B8", "7E9BE0", "E8C47A", "C490D4", "6EC4A0", "D4746A")
}
