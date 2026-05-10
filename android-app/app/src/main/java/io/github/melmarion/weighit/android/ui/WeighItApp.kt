package io.github.moranetz.weighit.android.ui

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Delete
import androidx.compose.material.icons.rounded.EditNote
import androidx.compose.material.icons.rounded.KeyboardArrowDown
import androidx.compose.material.icons.rounded.KeyboardArrowUp
import androidx.compose.material.icons.rounded.Menu
import androidx.compose.material.icons.rounded.MoreHoriz
import androidx.compose.material.icons.rounded.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.BottomSheetDefaults
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Divider
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardCapitalization
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.lifecycle.viewModelScope
import io.github.moranetz.weighit.android.data.BoardEntity
import io.github.moranetz.weighit.android.data.BoardSnapshot
import io.github.moranetz.weighit.android.data.EvidenceEntity
import io.github.moranetz.weighit.android.data.HypothesisColors
import io.github.moranetz.weighit.android.data.HypothesisEntity
import io.github.moranetz.weighit.android.data.Rating
import io.github.moranetz.weighit.android.data.Weight
import io.github.moranetz.weighit.android.data.WeighItRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

private val Bg = Color(0xFF111014)
private val Raised = Color.White.copy(alpha = 0.05f)
private val Border = Color.White.copy(alpha = 0.07f)
private val Accent = Color(0xFFEF8B6E)
private val AccentSecondary = Color(0xFFE8C47A)
private val Positive = Color(0xFF7EC49B)
private val Negative = Color(0xFFD4746A)
private val Warning = Color(0xFFE8C47A)
private val TextPrimary = Color(0xFFF0EBE6)
private val TextSecondary = Color(0xFF9A928A)
private val TextDim = Color(0xFF5A544E)
private val TextMuted = Color(0xFF3A3530)
private val AllRatings = listOf(
    Rating.STRONGLY_SUPPORTS,
    Rating.SUPPORTS,
    Rating.IRRELEVANT,
    Rating.CONTRADICTS,
    Rating.STRONGLY_CONTRADICTS
)

private fun colorFromHex(hex: String): Color = Color(android.graphics.Color.parseColor("#$hex"))

data class WeighItUiState(
    val boards: List<BoardSnapshot> = emptyList(),
    val activeBoardId: String? = null
) {
    val activeBoard: BoardSnapshot? = boards.firstOrNull { it.board.id == activeBoardId } ?: boards.firstOrNull()
}

class WeighItViewModel(
    private val repository: WeighItRepository
) : ViewModel() {
    private val activeBoardId = MutableStateFlow<String?>(null)

    val uiState: StateFlow<WeighItUiState> = combine(repository.observeBoards(), activeBoardId) { boards, active ->
        val chosen = active ?: boards.firstOrNull()?.board?.id
        WeighItUiState(boards = boards, activeBoardId = chosen)
    }.stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), WeighItUiState())

    init {
        viewModelScope.launch {
            if (!repository.hasBoards()) {
                val boardId = repository.createBoard(example = true)
                activeBoardId.value = boardId
            }
        }
    }

    fun selectBoard(boardId: String) {
        activeBoardId.value = boardId
    }

    fun newBoard() {
        viewModelScope.launch {
            activeBoardId.value = repository.createBoard()
        }
    }

    fun deleteBoard(board: BoardSnapshot) {
        viewModelScope.launch {
            repository.deleteBoard(board)
            val remaining = uiState.value.boards.filterNot { it.board.id == board.board.id }
            activeBoardId.value = remaining.firstOrNull()?.board?.id
            if (remaining.isEmpty()) {
                activeBoardId.value = repository.createBoard()
            }
        }
    }

    fun updateQuestion(board: BoardSnapshot, question: String) = viewModelScope.launch {
        repository.updateBoard(board.board.copy(question = question))
    }

    fun updateConclusion(board: BoardSnapshot, conclusion: String) = viewModelScope.launch {
        repository.updateBoard(board.board.copy(conclusion = conclusion))
    }

    fun addHypothesis(board: BoardSnapshot) = viewModelScope.launch {
        repository.upsertHypothesis(
            HypothesisEntity(
                boardId = board.board.id,
                colorHex = HypothesisColors.all[board.hypotheses.size % HypothesisColors.all.size],
                sortOrder = board.hypotheses.size
            )
        )
    }

    fun updateHypothesis(hypothesis: HypothesisEntity) = viewModelScope.launch {
        repository.upsertHypothesis(hypothesis)
    }

    fun deleteHypothesis(board: BoardSnapshot, hypothesisId: String) = viewModelScope.launch {
        repository.deleteHypothesis(board.board.id, hypothesisId)
    }

    fun addEvidence(board: BoardSnapshot) = viewModelScope.launch {
        repository.upsertEvidence(EvidenceEntity(boardId = board.board.id, sortOrder = board.evidence.size))
    }

    fun updateEvidence(evidence: EvidenceEntity) = viewModelScope.launch {
        repository.upsertEvidence(evidence)
    }

    fun deleteEvidence(board: BoardSnapshot, evidenceId: String) = viewModelScope.launch {
        repository.deleteEvidence(board.board.id, evidenceId)
    }

    fun moveEvidence(board: BoardSnapshot, evidenceId: String, delta: Int) = viewModelScope.launch {
        val items = board.sortedEvidence.toMutableList()
        val index = items.indexOfFirst { it.id == evidenceId }
        val targetIndex = index + delta
        if (index == -1 || targetIndex !in items.indices) return@launch
        val current = items[index]
        items[index] = items[targetIndex]
        items[targetIndex] = current
        items.forEachIndexed { sortIndex, item ->
            repository.upsertEvidence(item.copy(sortOrder = sortIndex))
        }
    }

    fun setRating(board: BoardSnapshot, evidenceId: String, hypothesisId: String, rating: Rating) = viewModelScope.launch {
        repository.setCell(board.board.id, evidenceId, hypothesisId, rating)
    }

    fun clearRating(board: BoardSnapshot, evidenceId: String, hypothesisId: String) = viewModelScope.launch {
        repository.clearRating(board.board.id, evidenceId, hypothesisId)
    }

    fun setNote(board: BoardSnapshot, evidenceId: String, hypothesisId: String, note: String) = viewModelScope.launch {
        repository.setCell(board.board.id, evidenceId, hypothesisId, board.rating(evidenceId, hypothesisId), note)
    }

    class Factory(
        private val repository: WeighItRepository
    ) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T = WeighItViewModel(repository) as T
    }
}

@Composable
fun WeighItApp(
    repository: WeighItRepository,
    onShareMarkdown: (String) -> Unit
) {
    val viewModel: WeighItViewModel = viewModel(factory = WeighItViewModel.Factory(repository))
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val board = uiState.activeBoard
    val snackbarHostState = remember { SnackbarHostState() }

    MaterialTheme(
        colorScheme = MaterialTheme.colorScheme.copy(
            background = Bg,
            surface = Bg,
            primary = Accent,
            secondary = AccentSecondary,
            onBackground = TextPrimary,
            onSurface = TextPrimary
        )
    ) {
        Surface(color = Bg, modifier = Modifier.fillMaxSize()) {
            if (board != null) {
                WeighItBoardScreen(
                    uiState = uiState,
                    board = board,
                    viewModel = viewModel,
                    snackbarHostState = snackbarHostState,
                    onShareMarkdown = onShareMarkdown
                )
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class, ExperimentalLayoutApi::class)
@Composable
private fun WeighItBoardScreen(
    uiState: WeighItUiState,
    board: BoardSnapshot,
    viewModel: WeighItViewModel,
    snackbarHostState: SnackbarHostState,
    onShareMarkdown: (String) -> Unit
) {
    var showBoards by remember { mutableStateOf(false) }
    var showResults by remember { mutableStateOf(false) }
    var selectedCell by remember { mutableStateOf<Pair<String, String>?>(null) }
    var pickerCell by remember { mutableStateOf<Pair<String, String>?>(null) }
    var showOverflow by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    Scaffold(
        containerColor = Bg,
        contentWindowInsets = WindowInsets.statusBars,
        topBar = {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(
                    modifier = Modifier.clickable { showBoards = true },
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Rounded.Menu, contentDescription = null, tint = Accent)
                    Spacer(Modifier.width(10.dp))
                    Column {
                        Text("Weigh It", color = TextPrimary, fontWeight = FontWeight.ExtraBold)
                        Text(board.displayName, color = TextDim, maxLines = 1, overflow = TextOverflow.Ellipsis, fontSize = 12.sp)
                    }
                }

                Spacer(Modifier.weight(1f))
                ProgressChip(percent = board.completionPercent)
                Box {
                    IconButton(onClick = { showOverflow = true }) {
                        Icon(Icons.Rounded.MoreHoriz, contentDescription = null, tint = TextSecondary)
                    }
                    DropdownMenu(expanded = showOverflow, onDismissRequest = { showOverflow = false }) {
                        DropdownMenuItem(
                            text = { Text("New board") },
                            onClick = {
                                viewModel.newBoard()
                                showOverflow = false
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("Export markdown") },
                            leadingIcon = { Icon(Icons.Rounded.Share, contentDescription = null) },
                            onClick = {
                                onShareMarkdown(board.exportMarkdown())
                                showOverflow = false
                            }
                        )
                    }
                }
            }
        },
        snackbarHost = { SnackbarHost(snackbarHostState) }
    ) { innerPadding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .background(
                    brush = Brush.verticalGradient(
                        listOf(Bg, Color(0xFF151318), Bg)
                    )
                )
                .padding(innerPadding)
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item {
                SectionCard {
                    SectionLabel("What are you trying to figure out?")
                    OutlinedTextField(
                        value = board.board.question,
                        onValueChange = { viewModel.updateQuestion(board, it) },
                        modifier = Modifier.fillMaxWidth(),
                        placeholder = { Text("e.g. Why are signups dropping?") },
                        colors = fieldColors(),
                        shape = RoundedCornerShape(12.dp),
                        keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences)
                    )
                }
            }

            item {
                SectionCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        SectionLabel("Possible explanations")
                        Spacer(Modifier.weight(1f))
                        if (board.hypotheses.size < 7) {
                            TextButton(onClick = { viewModel.addHypothesis(board) }) {
                                Icon(Icons.Rounded.Add, contentDescription = null, tint = Accent)
                                Spacer(Modifier.width(4.dp))
                                Text("+ add", color = Accent)
                            }
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        board.sortedHypotheses.forEach { hypothesis ->
                            HypothesisRow(
                                hypothesis = hypothesis,
                                canDelete = board.hypotheses.size > 2,
                                onChange = { viewModel.updateHypothesis(it) },
                                onDelete = { viewModel.deleteHypothesis(board, hypothesis.id) }
                            )
                        }
                    }
                }
            }

            item {
                SectionCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Column {
                            SectionLabel("What do you know so far?")
                            Text("Data, observations, gut feelings. Reorder with the arrow nubs.", color = TextDim, fontSize = 12.sp)
                        }
                        Spacer(Modifier.weight(1f))
                        TextButton(onClick = { viewModel.addEvidence(board) }) {
                            Icon(Icons.Rounded.Add, contentDescription = null, tint = Accent)
                            Spacer(Modifier.width(4.dp))
                            Text("+ add", color = Accent)
                        }
                    }
                    Spacer(Modifier.height(8.dp))
                    Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                        board.sortedEvidence.forEachIndexed { index, evidence ->
                            EvidenceRow(
                                evidence = evidence,
                                index = index,
                                canDelete = board.evidence.size > 1,
                                isFirst = index == 0,
                                isLast = index == board.sortedEvidence.lastIndex,
                                onChange = { viewModel.updateEvidence(it) },
                                onDelete = { viewModel.deleteEvidence(board, evidence.id) },
                                onMoveUp = { viewModel.moveEvidence(board, evidence.id, -1) },
                                onMoveDown = { viewModel.moveEvidence(board, evidence.id, 1) }
                            )
                        }
                    }
                }
            }

            item {
                SectionCard {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        SectionLabel("Weigh each piece against each explanation")
                        Spacer(Modifier.weight(1f))
                        if (board.filledCells > 0) {
                            Text("${board.filledCells}/${board.totalCells}", color = TextDim, fontSize = 12.sp)
                        }
                    }
                    Text("Tap a cell to rate it.", color = TextDim, fontSize = 12.sp)
                    Spacer(Modifier.height(8.dp))
                    FlowRow(horizontalArrangement = Arrangement.spacedBy(6.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                        AllRatings.forEach { rating: Rating ->
                            LegendChip(rating)
                        }
                    }
                    Spacer(Modifier.height(10.dp))
                    MatrixGrid(
                        board = board,
                        selectedCell = selectedCell,
                        pickerCell = pickerCell,
                        onSelect = { selectedCell = it },
                        onOpenPicker = { pickerCell = it },
                        onDismissPicker = { pickerCell = null },
                        onRate = { evidenceId: String, hypothesisId: String, rating: Rating ->
                            viewModel.setRating(board, evidenceId, hypothesisId, rating)
                        },
                        onClear = { evidenceId: String, hypothesisId: String ->
                            viewModel.clearRating(board, evidenceId, hypothesisId)
                        }
                    )
                    AnimatedVisibility(visible = selectedCell != null) {
                        val (evidenceId, hypothesisId) = selectedCell ?: "" to ""
                        val evidence = board.sortedEvidence.firstOrNull { it.id == evidenceId }
                        val hypothesis = board.sortedHypotheses.firstOrNull { it.id == hypothesisId }
                        if (evidence != null && hypothesis != null) {
                            NotePanel(
                                evidence = evidence,
                                hypothesis = hypothesis,
                                note = board.note(evidence.id, hypothesis.id),
                                onChange = { viewModel.setNote(board, evidence.id, hypothesis.id, it) },
                                onClose = { selectedCell = null }
                            )
                        }
                    }
                }
            }

            if (board.filledCells > 0) {
                item {
                    Button(
                        onClick = { showResults = !showResults },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = if (showResults) Raised else Accent,
                            contentColor = if (showResults) TextSecondary else Bg
                        ),
                        shape = RoundedCornerShape(14.dp)
                    ) {
                        Text(if (showResults) "Hide results" else "See what the evidence says")
                    }
                }
            }

            item {
                AnimatedVisibility(
                    visible = showResults,
                    enter = fadeIn() + slideInVertically { it / 4 },
                    exit = fadeOut() + slideOutVertically { it / 4 }
                ) {
                    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                        ResultsCard(board)
                        ConclusionCard(board, onConclusionChange = { viewModel.updateConclusion(board, it) })
                    }
                }
            }

            item {
                Text(
                    text = "Based on Analysis of Competing Hypotheses — a thinking technique from intelligence analysis. Made friendly.",
                    color = TextMuted,
                    fontSize = 11.sp,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 20.dp),
                    lineHeight = 16.sp
                )
            }
        }
    }

    if (showBoards) {
        ModalBottomSheet(
            onDismissRequest = { showBoards = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = false),
            containerColor = Color(0xFF17151A),
            dragHandle = { BottomSheetDefaults.DragHandle(color = TextDim) }
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .padding(bottom = 32.dp + WindowInsets.navigationBars.asPaddingValues().calculateBottomPadding()),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text("Your Boards", color = TextPrimary, fontWeight = FontWeight.Bold, fontSize = 20.sp)
                uiState.boards.forEach { item ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable {
                                viewModel.selectBoard(item.board.id)
                                showBoards = false
                            },
                        colors = CardDefaults.cardColors(containerColor = Raised)
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(14.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column(modifier = Modifier.weight(1f)) {
                                Text(item.displayName, color = if (item.board.id == board.board.id) Accent else TextPrimary, fontWeight = FontWeight.Bold)
                                Text("${item.completionPercent}% complete", color = TextDim, fontSize = 12.sp)
                            }
                            if (item.board.id == board.board.id) {
                                Icon(Icons.Rounded.Check, contentDescription = null, tint = Accent)
                            }
                            if (uiState.boards.size > 1) {
                                IconButton(onClick = {
                                    viewModel.deleteBoard(item)
                                    scope.launch { snackbarHostState.showSnackbar("Board deleted") }
                                }) {
                                    Icon(Icons.Rounded.Delete, contentDescription = null, tint = TextDim)
                                }
                            }
                        }
                    }
                }
                TextButton(onClick = { viewModel.newBoard() }) {
                    Icon(Icons.Rounded.Add, contentDescription = null, tint = Accent)
                    Spacer(Modifier.width(4.dp))
                    Text("New board", color = Accent)
                }
            }
        }
    }
}

@Composable
private fun SectionCard(content: @Composable ColumnScope.() -> Unit) {
    Card(
        colors = CardDefaults.cardColors(containerColor = Color.White.copy(alpha = 0.03f)),
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(20.dp),
        border = androidx.compose.foundation.BorderStroke(1.dp, Border)
    ) {
        Column(modifier = Modifier.padding(20.dp), content = content)
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(text, color = TextSecondary, fontWeight = FontWeight.SemiBold, fontSize = 14.sp)
}

@Composable
private fun ProgressChip(percent: Int) {
    Surface(shape = RoundedCornerShape(16.dp), color = Raised, border = androidx.compose.foundation.BorderStroke(1.dp, Border)) {
        Text(
            text = "$percent%",
            color = if (percent >= 100) Positive else Accent,
            fontWeight = FontWeight.ExtraBold,
            modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)
        )
    }
}

@Composable
private fun HypothesisRow(
    hypothesis: HypothesisEntity,
    canDelete: Boolean,
    onChange: (HypothesisEntity) -> Unit,
    onDelete: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Raised, RoundedCornerShape(12.dp))
            .border(1.dp, Border, RoundedCornerShape(12.dp))
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(Modifier.size(12.dp).background(colorFromHex(hypothesis.colorHex), CircleShape))
        Spacer(Modifier.width(10.dp))
        OutlinedTextField(
            value = hypothesis.name,
            onValueChange = { onChange(hypothesis.copy(name = it)) },
            modifier = Modifier.weight(1f),
            placeholder = { Text("Explanation…") },
            singleLine = false,
            colors = fieldColors(),
            textStyle = androidx.compose.ui.text.TextStyle(
                color = if (hypothesis.isRuledOut) TextSecondary else TextPrimary,
                textDecoration = if (hypothesis.isRuledOut) TextDecoration.LineThrough else TextDecoration.None
            )
        )
        Spacer(Modifier.width(8.dp))
        FilterChip(
            selected = hypothesis.isRuledOut,
            onClick = { onChange(hypothesis.copy(isRuledOut = !hypothesis.isRuledOut)) },
            label = { Text(if (hypothesis.isRuledOut) "undo" else "rule out") }
        )
        if (canDelete) {
            IconButton(onClick = onDelete) {
                Icon(Icons.Rounded.Close, contentDescription = null, tint = TextDim)
            }
        }
    }
}

@Composable
private fun EvidenceRow(
    evidence: EvidenceEntity,
    index: Int,
    canDelete: Boolean,
    isFirst: Boolean,
    isLast: Boolean,
    onChange: (EvidenceEntity) -> Unit,
    onDelete: () -> Unit,
    onMoveUp: () -> Unit,
    onMoveDown: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .background(Raised, RoundedCornerShape(12.dp))
            .border(1.dp, Border, RoundedCornerShape(12.dp))
            .padding(12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column {
            IconButton(onClick = onMoveUp, enabled = !isFirst) {
                Icon(Icons.Rounded.KeyboardArrowUp, contentDescription = null, tint = if (isFirst) TextMuted else TextDim)
            }
            IconButton(onClick = onMoveDown, enabled = !isLast) {
                Icon(Icons.Rounded.KeyboardArrowDown, contentDescription = null, tint = if (isLast) TextMuted else TextDim)
            }
        }
        Text("${index + 1}", color = TextMuted, fontWeight = FontWeight.Bold)
        Spacer(Modifier.width(8.dp))
        OutlinedTextField(
            value = evidence.text,
            onValueChange = { onChange(evidence.copy(text = it)) },
            modifier = Modifier.weight(1f),
            placeholder = { Text("Something you've observed…") },
            colors = fieldColors()
        )
        Spacer(Modifier.width(8.dp))
        Column(horizontalAlignment = Alignment.End) {
            WeightPicker("trust", Weight.fromRaw(evidence.credibility)) { onChange(evidence.copy(credibility = it.rawValue)) }
            WeightPicker("rel", Weight.fromRaw(evidence.relevance)) { onChange(evidence.copy(relevance = it.rawValue)) }
        }
        if (canDelete) {
            IconButton(onClick = onDelete) {
                Icon(Icons.Rounded.Close, contentDescription = null, tint = TextDim)
            }
        }
    }
}

@Composable
private fun WeightPicker(label: String, weight: Weight, onSelect: (Weight) -> Unit) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Text(label, color = TextDim, fontSize = 9.sp, fontWeight = FontWeight.SemiBold)
        Spacer(Modifier.width(4.dp))
        Weight.entries.forEach { option ->
            TextButton(onClick = { onSelect(option) }, contentPadding = androidx.compose.foundation.layout.PaddingValues(4.dp)) {
                Text(option.label, color = if (weight == option) Accent else TextDim, fontSize = 11.sp)
            }
        }
    }
}

@Composable
private fun LegendChip(rating: Rating) {
    val color = ratingColor(rating)
    Surface(
        color = color.copy(alpha = 0.15f),
        shape = RoundedCornerShape(8.dp)
    ) {
        Text(
            rating.shortLabel,
            color = color,
            fontSize = 10.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
        )
    }
}

@Composable
private fun MatrixGrid(
    board: BoardSnapshot,
    selectedCell: Pair<String, String>?,
    pickerCell: Pair<String, String>?,
    onSelect: (Pair<String, String>) -> Unit,
    onOpenPicker: (Pair<String, String>) -> Unit,
    onDismissPicker: () -> Unit,
    onRate: (String, String, Rating) -> Unit,
    onClear: (String, String) -> Unit
) {
    val scrollState = rememberScrollState()
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .border(1.dp, Border, RoundedCornerShape(14.dp))
            .background(Color.Black.copy(alpha = 0.15f), RoundedCornerShape(14.dp))
            .horizontalScroll(scrollState)
    ) {
        Row {
            HeaderCell("EVIDENCE", width = 160.dp)
            board.sortedHypotheses.forEachIndexed { index, hypothesis ->
                HeaderCell(if (hypothesis.name.isBlank()) "Expl. ${index + 1}" else hypothesis.name, width = 118.dp, dimmed = hypothesis.isRuledOut)
            }
        }
        board.sortedEvidence.forEachIndexed { evidenceIndex, evidence ->
            Row {
                BodyLabelCell(if (evidence.text.isBlank()) "Evidence ${evidenceIndex + 1}" else evidence.text)
                board.sortedHypotheses.forEach { hypothesis ->
                    val key = evidence.id to hypothesis.id
                    val rating = board.rating(evidence.id, hypothesis.id)
                    val note = board.note(evidence.id, hypothesis.id)
                    Box(
                        modifier = Modifier
                            .width(118.dp)
                            .height(76.dp)
                            .background(
                                if (hypothesis.isRuledOut) Color.White.copy(alpha = 0.01f)
                                else rating?.let { ratingColor(it).copy(alpha = 0.15f) } ?: Color.White.copy(alpha = 0.02f)
                            )
                            .border(
                                width = if (selectedCell == key) 2.dp else 0.5.dp,
                                color = if (selectedCell == key) Accent else Border,
                            )
                            .alpha(if (hypothesis.isRuledOut) 0.25f else 1f)
                            .clickable(enabled = !hypothesis.isRuledOut) { onOpenPicker(key) },
                        contentAlignment = Alignment.Center
                    ) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally) {
                            Text(
                                text = rating?.shortLabel ?: "+",
                                color = rating?.let(::ratingColor) ?: TextMuted,
                                fontSize = if (rating == null) 18.sp else 9.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                            if (note.isNotBlank()) {
                                Spacer(Modifier.height(4.dp))
                                Icon(Icons.Rounded.EditNote, contentDescription = null, tint = TextDim, modifier = Modifier.size(12.dp))
                            }
                        }
                    }
                    if (pickerCell == key) {
                        RatingDialog(
                            currentRating = rating,
                            onDismiss = onDismissPicker,
                            onRate = { onRate(evidence.id, hypothesis.id, it) },
                            onClear = { onClear(evidence.id, hypothesis.id) },
                            onNote = {
                                onSelect(key)
                                onDismissPicker()
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun HeaderCell(text: String, width: androidx.compose.ui.unit.Dp, dimmed: Boolean = false) {
    Box(
        modifier = Modifier
            .width(width)
            .height(64.dp)
            .background(Color(0xFF161416))
            .border(0.5.dp, Border),
        contentAlignment = Alignment.CenterStart
    ) {
        Text(
            text = text,
            color = TextSecondary,
            fontWeight = FontWeight.SemiBold,
            fontSize = 11.sp,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
            modifier = Modifier.padding(horizontal = 12.dp).alpha(if (dimmed) 0.35f else 1f)
        )
    }
}

@Composable
private fun BodyLabelCell(text: String) {
    Box(
        modifier = Modifier
            .width(160.dp)
            .height(76.dp)
            .background(Bg.copy(alpha = 0.5f))
            .border(0.5.dp, Border),
        contentAlignment = Alignment.CenterStart
    ) {
        Text(text, color = TextSecondary, fontSize = 13.sp, maxLines = 2, overflow = TextOverflow.Ellipsis, modifier = Modifier.padding(horizontal = 12.dp))
    }
}

@Composable
private fun RatingDialog(
    currentRating: Rating?,
    onDismiss: () -> Unit,
    onRate: (Rating) -> Unit,
    onClear: () -> Unit,
    onNote: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Rate this cell", color = TextPrimary) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                AllRatings.forEach { rating: Rating ->
                    TextButton(onClick = { onRate(rating); onDismiss() }) {
                        Text(rating.label, color = ratingColor(rating), modifier = Modifier.fillMaxWidth())
                    }
                }
            }
        },
        confirmButton = {
            Row {
                if (currentRating != null) {
                    TextButton(onClick = { onClear(); onDismiss() }) { Text("Clear", color = TextSecondary) }
                }
                TextButton(onClick = onNote) { Text("Add note", color = Accent) }
            }
        },
        containerColor = Color(0xFF18161B)
    )
}

@Composable
private fun NotePanel(
    evidence: EvidenceEntity,
    hypothesis: HypothesisEntity,
    note: String,
    onChange: (String) -> Unit,
    onClose: () -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 12.dp)
            .background(Accent.copy(alpha = 0.05f), RoundedCornerShape(14.dp))
            .border(1.dp, Accent.copy(alpha = 0.15f), RoundedCornerShape(14.dp))
            .padding(14.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                "${if (evidence.text.isBlank()) "Evidence" else evidence.text} → ${if (hypothesis.name.isBlank()) "Explanation" else hypothesis.name}",
                color = TextSecondary,
                fontWeight = FontWeight.SemiBold,
                fontSize = 12.sp,
                modifier = Modifier.weight(1f),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            IconButton(onClick = onClose) {
                Icon(Icons.Rounded.Close, contentDescription = null, tint = TextDim)
            }
        }
        OutlinedTextField(
            value = note,
            onValueChange = onChange,
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Why did you rate it this way?") },
            colors = fieldColors()
        )
    }
}

@Composable
private fun ResultsCard(board: BoardSnapshot) {
    Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
        SectionCard {
            SectionLabel("Which explanation holds up best?")
            Spacer(Modifier.height(8.dp))
            board.rankedHypotheses.forEachIndexed { index, item ->
                val best = index == 0
                Row(verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
                    Text("${index + 1}", color = if (best) Accent else TextMuted, fontWeight = FontWeight.ExtraBold, fontSize = 22.sp)
                    Spacer(Modifier.width(12.dp))
                    Box(Modifier.size(12.dp).background(colorFromHex(item.hypothesis.colorHex), CircleShape))
                    Spacer(Modifier.width(12.dp))
                    Column(modifier = Modifier.weight(1f)) {
                        Text(if (item.hypothesis.name.isBlank()) "Explanation ${index + 1}" else item.hypothesis.name, color = TextPrimary, fontWeight = FontWeight.SemiBold)
                        Spacer(Modifier.height(6.dp))
                        Box(modifier = Modifier.fillMaxWidth().height(5.dp).background(Color.White.copy(alpha = 0.04f), RoundedCornerShape(3.dp))) {
                            Box(
                                modifier = Modifier
                                    .fillMaxWidth(fraction = (kotlin.math.abs(item.score).toFloat() / board.maxAbsScore.toFloat()).coerceAtLeast(0.04f))
                                    .height(5.dp)
                                    .background(
                                        if (item.score >= 0) colorFromHex(item.hypothesis.colorHex) else Negative,
                                        RoundedCornerShape(3.dp)
                                    )
                            )
                        }
                    }
                    Spacer(Modifier.width(12.dp))
                    Text(if (item.score > 0) "+${item.score}" else item.score.toString(), color = if (item.score > 0) Positive else if (item.score < 0) Negative else TextDim, fontWeight = FontWeight.ExtraBold)
                }
                Spacer(Modifier.height(8.dp))
                HorizontalDivider(color = Border)
                Spacer(Modifier.height(8.dp))
            }
            if (board.ruledOutHypotheses.isNotEmpty()) {
                Text(
                    "Ruled out: ${board.ruledOutHypotheses.joinToString { if (it.name.isBlank()) "Unnamed" else it.name }}",
                    color = Negative,
                    textDecoration = TextDecoration.LineThrough
                )
                Spacer(Modifier.height(8.dp))
            }
            Surface(color = Accent.copy(alpha = 0.05f), shape = RoundedCornerShape(12.dp)) {
                Text(
                    "The best explanation isn't the one with the most support — it's the one with the fewest contradictions.",
                    color = TextSecondary,
                    modifier = Modifier.padding(12.dp),
                    fontSize = 12.sp,
                    lineHeight = 18.sp
                )
            }
        }

        if (board.highDiagnostics.isNotEmpty() || board.lowDiagnostics.isNotEmpty()) {
            SectionCard {
                SectionLabel("Which evidence actually matters?")
                Spacer(Modifier.height(8.dp))
                if (board.highDiagnostics.isNotEmpty()) {
                    Text("Helps you decide:", color = Positive, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                    Spacer(Modifier.height(6.dp))
                    board.highDiagnostics.forEach {
                        DiagnosticPill(if (it.evidence.text.isBlank()) "Unnamed" else it.evidence.text, Positive)
                    }
                }
                if (board.lowDiagnostics.isNotEmpty()) {
                    Spacer(Modifier.height(10.dp))
                    Text("Doesn't differentiate:", color = Warning, fontWeight = FontWeight.Bold, fontSize = 12.sp)
                    Spacer(Modifier.height(6.dp))
                    board.lowDiagnostics.forEach {
                        DiagnosticPill(if (it.evidence.text.isBlank()) "Unnamed" else it.evidence.text, Warning)
                    }
                }
            }
        }

        if (board.biasWarnings.isNotEmpty()) {
            SectionCard {
                Text("Honest check", color = Warning, fontWeight = FontWeight.Bold)
                Spacer(Modifier.height(8.dp))
                board.biasWarnings.forEach {
                    Text(it, color = Color(0xFFB0A080), lineHeight = 18.sp)
                }
            }
        }
    }
}

@Composable
private fun DiagnosticPill(text: String, color: Color) {
    Surface(color = color.copy(alpha = 0.08f), shape = RoundedCornerShape(10.dp), border = androidx.compose.foundation.BorderStroke(1.dp, color.copy(alpha = 0.18f))) {
        Text(text, color = color, modifier = Modifier.fillMaxWidth().padding(10.dp))
    }
}

@Composable
private fun ConclusionCard(board: BoardSnapshot, onConclusionChange: (String) -> Unit) {
    SectionCard {
        Text("So, what do you think?", color = Accent, fontWeight = FontWeight.Bold)
        Text("Write your conclusion. Included in exports.", color = TextDim, fontSize = 12.sp)
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = board.board.conclusion,
            onValueChange = onConclusionChange,
            modifier = Modifier.fillMaxWidth(),
            placeholder = { Text("Based on the evidence, I believe…") },
            colors = fieldColors()
        )
    }
}

@Composable
private fun fieldColors() = androidx.compose.material3.OutlinedTextFieldDefaults.colors(
    focusedContainerColor = Raised,
    unfocusedContainerColor = Raised,
    focusedBorderColor = Accent.copy(alpha = 0.35f),
    unfocusedBorderColor = Border,
    cursorColor = Accent,
    focusedTextColor = TextPrimary,
    unfocusedTextColor = TextPrimary,
    focusedPlaceholderColor = TextDim,
    unfocusedPlaceholderColor = TextDim
)

private fun ratingColor(rating: Rating): Color = when (rating) {
    Rating.STRONGLY_SUPPORTS -> Color(0xFF7EC49B)
    Rating.SUPPORTS -> Color(0xFFA0CFA0)
    Rating.IRRELEVANT -> Color(0xFF8A8278)
    Rating.CONTRADICTS -> Color(0xFFE8C47A)
    Rating.STRONGLY_CONTRADICTS -> Color(0xFFD4746A)
}
