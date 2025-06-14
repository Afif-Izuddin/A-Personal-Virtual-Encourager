package com.example.fyp_a_personal_virtual_encourager_test_1 // Replace with your actual package name

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.util.Log
import android.widget.RemoteViews
import androidx.work.*
import es.antonborri.home_widget.HomeWidgetPlugin
import java.util.concurrent.TimeUnit

const val WIDGET_ID_KEY = "widgetId"
const val QUOTE_KEY = "widget_daily_quote"
const val AUTHOR_KEY = "widget_daily_author"
const val PREFS_NAME = "widget_prefs"

class DailyQuoteWidgetProvider : AppWidgetProvider() {

    override fun onUpdate(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetIds: IntArray?
    ) {
        appWidgetIds?.forEach { appWidgetId ->
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d("DailyQuoteWidget", "onEnabled")
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d("DailyQuoteWidget", "onDisabled")
    }
}

internal fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
) {
    val widgetData = HomeWidgetPlugin.getData(context)
    val quote = widgetData.getString("QUOTE_KEY", "")
    val author = widgetData.getString("QUOTE_AUTHOR", "")

    val views = RemoteViews(context.packageName, R.layout.daily_quote_widget_provider).apply {
        setTextViewText(R.id.widget_quote, quote)
        setTextViewText(R.id.widget_author, if (!author.isNullOrBlank()) "- $author" else "")
    }

    appWidgetManager.updateAppWidget(appWidgetId, views)
}