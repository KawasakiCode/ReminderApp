package com.example.reminder_app

import android.content.Context
import android.content.Intent
import android.text.SpannableString
import android.text.Spanned
import android.text.style.StrikethroughSpan
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import androidx.core.content.ContextCompat

/**
 * RemoteViewsService + RemoteViewsFactory feeding the widget's ListView.
 * Bound only by the system widget host (BIND_REMOTEVIEWS permission on the
 * service declaration). Rows are rendered purely from the Dart-maintained
 * JSON snapshot.
 */
class TodoWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory =
        TodoRemoteViewsFactory(applicationContext)
}

class TodoRemoteViewsFactory(
    private val context: Context,
) : RemoteViewsService.RemoteViewsFactory {

    private var todos: List<SnapshotTodo> = emptyList()

    override fun onCreate() {
        // Data is loaded in onDataSetChanged, which the host calls before the
        // first getViewAt pass.
    }

    /**
     * Called on a binder thread whenever notifyAppWidgetViewDataChanged
     * fires — blocking I/O is explicitly allowed here, so this is where the
     * snapshot is (re)read.
     */
    override fun onDataSetChanged() {
        val snapshot = TodaySnapshot.load(context)
        // After midnight a not-yet-rewritten snapshot counts as empty; the
        // widget shows the empty state instead of yesterday's todos. Unlike
        // the notification, the widget also lists *completed* todos
        // (struck through), so the day stays glanceable.
        todos = if (snapshot?.isForToday == true) snapshot.todos else emptyList()
    }

    override fun onDestroy() {
        todos = emptyList()
    }

    override fun getCount(): Int = todos.size

    override fun getViewAt(position: Int): RemoteViews {
        val todo = todos[position]
        return RemoteViews(context.packageName, R.layout.todo_widget_item).apply {
            // StrikethroughSpan implements ParcelableSpan, so it survives the
            // RemoteViews parcel — no second TextView needed for "done".
            val title: CharSequence = if (todo.done) {
                SpannableString(todo.title).apply {
                    setSpan(StrikethroughSpan(), 0, length, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                }
            } else {
                todo.title
            }
            setTextViewText(R.id.item_title, title)
            setTextViewText(R.id.item_time, todo.time ?: context.getString(R.string.all_day))

            setInt(
                R.id.item_color,
                "setBackgroundColor",
                todo.color ?: ContextCompat.getColor(context, R.color.accent),
            )
            setImageViewResource(
                R.id.item_check,
                if (todo.done) R.drawable.ic_check_on else R.drawable.ic_check_off,
            )

            // Collection rows can't carry their own PendingIntent; they add a
            // fill-in (the todo id) onto the provider's mutable template.
            setOnClickFillInIntent(
                R.id.item_root,
                Intent().putExtra(TodoActionReceiver.EXTRA_TODO_ID, todo.id),
            )
        }
    }

    override fun getLoadingView(): RemoteViews =
        RemoteViews(context.packageName, R.layout.todo_widget_loading)

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = todos[position].id.toLong()

    override fun hasStableIds(): Boolean = true
}
