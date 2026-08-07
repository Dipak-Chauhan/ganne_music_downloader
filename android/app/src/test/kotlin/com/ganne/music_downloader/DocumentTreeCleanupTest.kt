package com.ganne.music_downloader

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class DocumentTreeCleanupTest {
    @Test
    fun prunesEmptyDirectoriesWithoutDeletingFiles() {
        val root = FakeDocument(directory = true)
        val emptyParent = root.addDirectory()
        val emptyChild = emptyParent.addDirectory()
        val userFile = root.addFile()

        val deleted = pruneEmptyDirectories(
            root,
            isDirectory = { it.directory },
            listChildren = { it.children.toList() },
            deleteDirectory = { it.delete() },
        )

        assertEquals(2, deleted)
        assertTrue(emptyParent.deleted)
        assertTrue(emptyChild.deleted)
        assertFalse(root.deleted)
        assertFalse(userFile.deleted)
        assertEquals(listOf(userFile), root.children)
    }

    private class FakeDocument(
        val directory: Boolean,
        private val parent: FakeDocument? = null,
    ) {
        val children = mutableListOf<FakeDocument>()
        var deleted = false

        fun addDirectory() = FakeDocument(directory = true, parent = this).also {
            children.add(it)
        }

        fun addFile() = FakeDocument(directory = false, parent = this).also {
            children.add(it)
        }

        fun delete(): Boolean {
            check(directory)
            if (children.isNotEmpty()) return false
            deleted = true
            parent?.children?.remove(this)
            return true
        }
    }
}
