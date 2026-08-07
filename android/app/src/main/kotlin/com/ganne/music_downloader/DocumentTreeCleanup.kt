package com.ganne.music_downloader

internal fun <T> pruneEmptyDirectories(
    root: T,
    isDirectory: (T) -> Boolean,
    listChildren: (T) -> List<T>,
    deleteDirectory: (T) -> Boolean,
): Int {
    if (!isDirectory(root)) return 0

    var deleted = 0
    for (child in listChildren(root)) {
        if (isDirectory(child)) {
            deleted += pruneEmptyDirectories(
                child,
                isDirectory,
                listChildren,
                deleteDirectory,
            )
        }
    }
    if (listChildren(root).isEmpty() && deleteDirectory(root)) deleted++
    return deleted
}
