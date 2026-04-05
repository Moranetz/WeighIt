package io.github.melmarion.weighit.android

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.room.Room
import io.github.melmarion.weighit.android.data.WeighItDatabase
import io.github.melmarion.weighit.android.data.WeighItRepository
import io.github.melmarion.weighit.android.ui.WeighItApp

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()

        val database = Room.databaseBuilder(
            applicationContext,
            WeighItDatabase::class.java,
            "weighit.db"
        ).fallbackToDestructiveMigration().build()

        val repository = WeighItRepository(database.boardDao())

        setContent {
            WeighItApp(
                repository = repository,
                onShareMarkdown = { markdown ->
                    val sendIntent = Intent(Intent.ACTION_SEND).apply {
                        type = "text/markdown"
                        putExtra(Intent.EXTRA_TEXT, markdown)
                    }
                    startActivity(Intent.createChooser(sendIntent, "Export board"))
                }
            )
        }
    }
}
